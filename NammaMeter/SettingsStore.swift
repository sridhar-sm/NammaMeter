import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
  var settings: MeterSettings {
    didSet {
      guard isLoaded, !isSyncingFromProfile else { return }
      scheduleSettingsCommit()
    }
  }

  var profiles: [CityFareProfile] {
    state.profiles
  }

  var selectedCityId: String? {
    state.selectedCityId
  }

  @ObservationIgnored private let persistence: FareProfilePersistence
  @ObservationIgnored private var isLoaded = false
  @ObservationIgnored private var saveTask: Task<Void, Never>?
  @ObservationIgnored private var commitTask: Task<Void, Never>?
  @ObservationIgnored private var isSyncingFromProfile = false
  @ObservationIgnored private var state: FareProfileSettings

  init(fileURL: URL = SettingsStore.defaultURL) {
    self.persistence = FareProfilePersistence(url: fileURL)
    self.settings = MeterSettings.bengaluruDefault
    self.state = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: nil,
      profiles: [],
      catalogVersionApplied: 0
    )
    Task { await load() }
  }

  func resetToDefaults() {
    state.selectedCityId = FareCatalog.defaultCityId
    if state.profiles.isEmpty {
      state.profiles = FareCatalog.entries.map(\.profile)
      state.catalogVersionApplied = FareCatalog.currentVersion
    } else if !state.profiles.contains(where: { $0.cityId == FareCatalog.defaultCityId }) {
      state.profiles.append(FareCatalog.defaultProfile)
    }
    syncSettingsFromActiveProfile()
    scheduleSave()
  }

  private func load() async {
    var didMutate = false
    if let decoded = await persistence.load() {
      state = decoded
    } else {
      state = FareProfileSettings(
        schemaVersion: FareProfileSettings.currentSchemaVersion,
        selectedCityId: FareCatalog.defaultCityId,
        profiles: FareCatalog.entries.map(\.profile),
        catalogVersionApplied: FareCatalog.currentVersion
      )
      didMutate = true
    }

    if state.schemaVersion != FareProfileSettings.currentSchemaVersion {
      state.schemaVersion = FareProfileSettings.currentSchemaVersion
      didMutate = true
    }

    if applyCatalogUpdatesIfNeeded() {
      didMutate = true
    }
    if ensureMinimumProfile() {
      didMutate = true
    }
    if normalizeSelection() {
      didMutate = true
    }

    syncSettingsFromActiveProfile()
    isLoaded = true

    if didMutate {
      await save()
    }
  }

  private func applyCatalogUpdatesIfNeeded() -> Bool {
    guard state.catalogVersionApplied < FareCatalog.currentVersion else { return false }
    let existingIds = Set(state.profiles.map(\.id))
    let newEntries = FareCatalog.entries.filter { $0.introducedInVersion > state.catalogVersionApplied }
    let newProfiles = newEntries.map(\.profile).filter { !existingIds.contains($0.id) }
    if !newProfiles.isEmpty {
      state.profiles.append(contentsOf: newProfiles)
    }
    state.catalogVersionApplied = FareCatalog.currentVersion
    return true
  }

  private func ensureMinimumProfile() -> Bool {
    guard state.profiles.isEmpty else { return false }
    state.profiles = [FareCatalog.defaultProfile]
    return true
  }

  private func normalizeSelection() -> Bool {
    let selectedId = state.selectedCityId
    let hasSelected = selectedId != nil && state.profiles.contains { $0.cityId == selectedId }
    if hasSelected {
      return false
    }

    if !state.profiles.contains(where: { $0.cityId == FareCatalog.defaultCityId }) {
      state.profiles.append(FareCatalog.defaultProfile)
    }
    state.selectedCityId = FareCatalog.defaultCityId
    return true
  }

  private func scheduleSettingsCommit() {
    commitTask?.cancel()
    commitTask = Task { @MainActor [weak self] in
      guard let self else { return }
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }
      self.commitSettingsChange()
    }
  }

  private func commitSettingsChange() {
    let cityId = effectiveCityId
    let activeProfile = activeProfile(for: cityId, on: Date()) ?? FareCatalog.defaultProfile
    let activeSettings = MeterSettings(profile: activeProfile)
    guard activeSettings != settings else { return }

    let effectiveFrom = Date()
    let newProfile = CityFareProfile(
      id: UUID().uuidString,
      cityId: cityId,
      name: activeProfile.name,
      cityKey: activeProfile.cityKey,
      rates: FareRates(settings: settings),
      multipliers: FareMultipliers(settings: settings),
      nightWindow: NightFareWindow(settings: settings),
      waitCharges: WaitingChargePolicy(settings: settings),
      effectiveFrom: effectiveFrom
    )
    state.profiles.append(newProfile)
    state.selectedCityId = cityId
    scheduleSave()
  }

  private func syncSettingsFromActiveProfile() {
    commitTask?.cancel()
    let cityId = effectiveCityId
    let activeProfile = activeProfile(for: cityId, on: Date()) ?? FareCatalog.defaultProfile
    let newSettings = MeterSettings(profile: activeProfile)
    isSyncingFromProfile = true
    settings = newSettings
    isSyncingFromProfile = false
  }

  private var effectiveCityId: String {
    state.selectedCityId ?? FareCatalog.defaultCityId
  }

  private func activeProfile(for cityId: String, on date: Date) -> CityFareProfile? {
    let candidates = state.profiles.filter { $0.cityId == cityId }
    guard !candidates.isEmpty else { return nil }

    // Compare using device-local time; effectiveFrom is stored without city timezone lookup.
    let effectiveProfiles = candidates.filter { $0.effectiveFrom <= date }

    if let active = effectiveProfiles.max(by: { $0.effectiveFrom < $1.effectiveFrom }) {
      return active
    }
    return candidates.min(by: { $0.effectiveFrom < $1.effectiveFrom })
  }

  private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task { await save() }
  }

  private func save() async {
    guard !Task.isCancelled, isLoaded else { return }
    await persistence.save(state)
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("fare-profiles.json")
  }
}

private actor FareProfilePersistence {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func load() -> FareProfileSettings? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(FareProfileSettings.self, from: data)
  }

  func save(_ settings: FareProfileSettings) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(settings) else { return }
    try? data.write(to: url, options: [.atomic])
  }
}
