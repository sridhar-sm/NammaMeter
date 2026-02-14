import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class SettingsStore {
  // Theme preference loaded eagerly to prevent blocking during view rendering
  // Defaults to "system" if no preference is stored
  var themePreference: String {
    didSet {
      // Persist changes to UserDefaults
      UserDefaults.standard.set(themePreference, forKey: "themePreference")
    }
  }

  // Meter display preferences - persisted to UserDefaults
  var meterFaceStyle: String {
    didSet {
      UserDefaults.standard.set(meterFaceStyle, forKey: "meterFaceStyle")
    }
  }

  var meterRenderMode: String {
    didSet {
      UserDefaults.standard.set(meterRenderMode, forKey: "meterRenderMode")
    }
  }

  var digitWheelStyle: String {
    didSet {
      UserDefaults.standard.set(digitWheelStyle, forKey: "digitWheelStyle")
    }
  }

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

  var availableCities: [CityFareProfile] {
    var latestByCityId: [String: CityFareProfile] = [:]
    for profile in state.profiles {
      if let existing = latestByCityId[profile.cityId] {
        if profile.effectiveFrom > existing.effectiveFrom {
          latestByCityId[profile.cityId] = profile
        }
      } else {
        latestByCityId[profile.cityId] = profile
      }
    }
    return latestByCityId.values.sorted { $0.name < $1.name }
  }

  @ObservationIgnored private let persistence: FareProfilePersistence
  @ObservationIgnored private var isLoaded = false
  @ObservationIgnored private var saveTask: Task<Void, Never>?
  @ObservationIgnored private var commitTask: Task<Void, Never>?

  // Prevents infinite sync loops in the bidirectional settings update mechanism:
  // - When true: User is viewing a profile, changes flow Profile → MeterSettings (read-only)
  // - When false: User edited settings, changes flow MeterSettings → Profile (creates new version)
  // Without this flag, syncSettingsFromActiveProfile() would trigger didSet, causing commitSettingsChange(),
  // which would create a new profile and trigger another sync, creating an infinite loop.
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

    // Load theme preference from UserDefaults during initialization
    // Falls back to "system" if no preference is stored
    self.themePreference = UserDefaults.standard.string(forKey: "themePreference") ?? "system"

    // Load meter display preferences from UserDefaults
    // Falls back to default values if not stored
    self.meterFaceStyle = UserDefaults.standard.string(forKey: "meterFaceStyle") ?? MeterFaceStyle.superMeter.rawValue
    self.meterRenderMode = UserDefaults.standard.string(forKey: "meterRenderMode") ?? MeterRenderMode.full.rawValue
    self.digitWheelStyle = UserDefaults.standard.string(forKey: "digitWheelStyle") ?? DigitWheelStyle.disk.rawValue

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

  func selectCity(_ cityId: String) {
    guard state.profiles.contains(where: { $0.cityId == cityId }) else { return }
    state.selectedCityId = cityId
    syncSettingsFromActiveProfile()
    scheduleSave()
    Log.fare.info("Selected city: \(cityId)")
  }

  func addCity(_ profile: CityFareProfile) {
    state.profiles.append(profile)
    state.selectedCityId = profile.cityId
    syncSettingsFromActiveProfile()
    scheduleSave()
  }

  func addFareProfile(_ profile: CityFareProfile) {
    state.profiles.append(profile)
    scheduleSave()
  }

  func deleteFareProfile(_ profileId: String) {
    state.profiles.removeAll { $0.id == profileId }

    if let selectedId = state.selectedCityId,
       !state.profiles.contains(where: { $0.cityId == selectedId }) {
      fallbackToDefaultCity()
    }
    scheduleSave()
  }

  func deleteCity(_ cityId: String) {
    state.profiles.removeAll { $0.cityId == cityId }

    if state.selectedCityId == cityId {
      fallbackToDefaultCity()
    }
    scheduleSave()
  }

  private func fallbackToDefaultCity() {
    if state.profiles.contains(where: { $0.cityId == FareCatalog.defaultCityId }) {
      state.selectedCityId = FareCatalog.defaultCityId
    } else if let first = state.profiles.first {
      state.selectedCityId = first.cityId
    } else {
      state.profiles = [FareCatalog.defaultProfile]
      state.selectedCityId = FareCatalog.defaultCityId
    }
    syncSettingsFromActiveProfile()
  }

  func fareProfiles(for cityId: String) -> [CityFareProfile] {
    state.profiles
      .filter { $0.cityId == cityId }
      .sorted { $0.effectiveFrom > $1.effectiveFrom }
  }

  func isCatalogCity(_ cityId: String) -> Bool {
    FareCatalog.entries.contains { $0.profile.cityId == cityId }
  }

  // MARK: - WhatIf Favorites

  var whatIfFavorites: [WhatIfFavorite] {
    state.whatIfFavorites
  }

  func addWhatIfFavorite(_ favorite: WhatIfFavorite) {
    guard state.whatIfFavorites.count < 3 else { return }
    guard !state.whatIfFavorites.contains(where: { $0.id == favorite.id }) else { return }
    state.whatIfFavorites.append(favorite)
    scheduleSave()
  }

  func removeWhatIfFavorite(_ favorite: WhatIfFavorite) {
    state.whatIfFavorites.removeAll { $0.id == favorite.id }
    scheduleSave()
  }

  func whatIfProfile(for favorite: WhatIfFavorite) -> CityFareProfile? {
    let candidates = state.profiles.filter {
      $0.cityId == favorite.cityId && $0.vehicleType == favorite.vehicleType
    }
    let now = Date()
    let effective = candidates.filter { $0.effectiveFrom <= now }
    if let active = effective.max(by: { $0.effectiveFrom < $1.effectiveFrom }) {
      return active
    }
    return candidates.min(by: { $0.effectiveFrom < $1.effectiveFrom })
  }

  var activeCityInfo: (cityId: String, cityName: String) {
    let cityId = effectiveCityId
    let profile = activeProfile(for: cityId, on: Date()) ?? FareCatalog.defaultProfile
    return (cityId: cityId, cityName: profile.name)
  }

  /// Loads and migrates fare profile settings from persistence.
  ///
  /// **Migration Orchestration:**
  /// This method runs a series of migrations in a specific order to ensure data integrity.
  /// All migrations are idempotent and can safely run multiple times.
  ///
  /// **Migration Order (dependencies matter):**
  /// 1. **Load or seed**: Load existing data, or seed with catalog defaults on first run
  /// 2. **Schema version bump**: Update schema version to current (future: version-specific migrations)
  /// 3. **Catalog updates**: Append new catalog profiles introduced since last version
  /// 4. **Minimum profile**: Safety net - ensure at least one profile exists
  /// 5. **Normalize selection**: Validate selected city exists, fallback to default if invalid
  ///
  /// **Why order matters:**
  /// - ensureMinimumProfile() must run before normalizeSelection() (selection needs profiles to exist)
  /// - applyCatalogUpdatesIfNeeded() should run early to populate profiles before validation
  /// - Schema version bump happens first to enable future version-specific transformations
  ///
  /// **Version Management:**
  /// - **Schema version** (currently v2): Tracks FareProfileSettings structure changes
  ///   - Enables version-specific migrations in the future
  ///   - Currently only bumped, no version-specific logic yet
  /// - **Catalog version** (currently v2): Tracks which catalog profiles user has seen
  ///   - Prevents re-adding profiles user previously deleted
  ///   - Uses introducedInVersion field to track when each profile was added
  ///
  /// **Mutation Tracking:**
  /// Tracks whether any migration modified state to avoid unnecessary saves.
  private func load() async {
    var didMutate = false

    // Step 1: Load existing data or seed with catalog defaults
    if let decoded = await persistence.load() {
      state = decoded
      Log.persistence.info("Loaded fare profiles: \(decoded.profiles.count) profiles, selected=\(decoded.selectedCityId ?? "none")")
    } else {
      // First run: seed with all catalog profiles
      state = FareProfileSettings(
        schemaVersion: FareProfileSettings.currentSchemaVersion,
        selectedCityId: FareCatalog.defaultCityId,
        profiles: FareCatalog.entries.map(\.profile),
        catalogVersionApplied: FareCatalog.currentVersion
      )
      Log.persistence.info("No existing fare profiles, using catalog defaults")
      didMutate = true
    }

    // Step 2: Bump schema version if needed
    // Future: Add version-specific migrations here (e.g., if schemaVersion == 1 { migrateV1toV2() })
    if state.schemaVersion != FareProfileSettings.currentSchemaVersion {
      state.schemaVersion = FareProfileSettings.currentSchemaVersion
      didMutate = true
    }

    // Step 3: Apply catalog updates (append new profiles)
    if applyCatalogUpdatesIfNeeded() {
      didMutate = true
    }

    // Step 4: Ensure at least one profile exists (safety net)
    if ensureMinimumProfile() {
      didMutate = true
    }

    // Step 5: Validate and normalize selection
    if normalizeSelection() {
      didMutate = true
    }

    // Sync MeterSettings from the active profile for the selected city
    syncSettingsFromActiveProfile()
    isLoaded = true

    // Save if any migration modified state
    if didMutate {
      await save()
    }
  }

  /// Applies catalog updates by appending new profiles introduced since the last catalog version.
  ///
  /// **Catalog Update Philosophy: Append-Only**
  /// - Never removes or modifies existing profiles (respects user deletions)
  /// - Only appends profiles that don't already exist (by ID)
  /// - Uses introducedInVersion to track when each profile was added to catalog
  ///
  /// **How it works:**
  /// 1. Check if catalog version is newer than last applied version
  /// 2. Filter catalog entries introduced after catalogVersionApplied
  /// 3. Append only profiles not already in user's collection (by ID)
  /// 4. Bump catalogVersionApplied to current version
  ///
  /// **Example scenario:**
  /// - User has catalogVersionApplied=1 (Bengaluru only)
  /// - Catalog bumps to v2, adds Mandya (introducedInVersion=2)
  /// - This migration appends Mandya profile to user's profiles
  /// - catalogVersionApplied updated to 2
  ///
  /// **User deletions are respected:**
  /// If user deletes a catalog profile, it won't be re-added because catalogVersionApplied
  /// already tracks that the user has seen that version.
  ///
  /// - Returns: `true` if catalog was updated, `false` if already up-to-date
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

  /// Ensures at least one profile exists by adding the default profile if needed.
  ///
  /// **Safety Net Migration:**
  /// This is a fail-safe that prevents the app from entering an invalid state with zero profiles.
  /// Under normal circumstances, this should never trigger because:
  /// - First run: load() seeds with all catalog profiles
  /// - Catalog updates: applyCatalogUpdatesIfNeeded() adds profiles
  /// - User deletions: UI prevents deleting the last profile
  ///
  /// **When it triggers:**
  /// - Corrupted data file with empty profiles array
  /// - Future refactoring bugs that clear profiles accidentally
  /// - Edge cases during migration development
  ///
  /// **Default profile:**
  /// Uses Bengaluru (FareCatalog.defaultProfile) as the fallback city.
  ///
  /// **Idempotency:**
  /// Safe to run multiple times - only adds profile if array is empty.
  ///
  /// - Returns: `true` if default profile was added, `false` if profiles already exist
  private func ensureMinimumProfile() -> Bool {
    guard state.profiles.isEmpty else { return false }
    state.profiles = [FareCatalog.defaultProfile]
    return true
  }

  /// Validates the selected city and falls back to default if invalid.
  ///
  /// **Selection Validation:**
  /// Ensures selectedCityId points to a city that actually exists in profiles.
  /// This prevents crashes or undefined behavior when accessing the active profile.
  ///
  /// **When it triggers:**
  /// - selectedCityId is nil (no city selected)
  /// - selectedCityId references a city not in profiles (user deleted their selected city)
  /// - Data corruption or migration bugs
  ///
  /// **Fallback strategy:**
  /// 1. Check if default city (Bengaluru) exists in profiles
  /// 2. If not, append default profile first
  /// 3. Set selectedCityId to default city
  ///
  /// **Why append default profile?**
  /// Ensures the selected city always has a valid profile. Without this, we'd select
  /// a city with no profiles, causing activeProfile() to return nil.
  ///
  /// **Dependency:**
  /// Should run AFTER ensureMinimumProfile() to avoid redundant default profile addition.
  /// However, it's safe to run in any order - both migrations are idempotent.
  ///
  /// **Idempotency:**
  /// Safe to run multiple times - only modifies state if selection is invalid.
  ///
  /// - Returns: `true` if selection was normalized, `false` if selection is already valid
  private func normalizeSelection() -> Bool {
    let selectedId = state.selectedCityId
    let hasSelected = selectedId != nil && state.profiles.contains { $0.cityId == selectedId }
    if hasSelected {
      return false
    }

    // Ensure default city profile exists before selecting it
    if !state.profiles.contains(where: { $0.cityId == FareCatalog.defaultCityId }) {
      state.profiles.append(FareCatalog.defaultProfile)
    }
    state.selectedCityId = FareCatalog.defaultCityId
    return true
  }

  /// Schedules a debounced commit of user settings changes to a new profile version.
  ///
  /// **Debouncing Strategy:**
  /// Waits 500ms before committing to avoid creating excessive profile versions during
  /// rapid user edits (e.g., typing in a text field, dragging a slider).
  ///
  /// **Triggered by:**
  /// - settings.didSet when isLoaded=true and isSyncingFromProfile=false
  /// - User modifies any MeterSettings field (fares, multipliers, night window, etc.)
  ///
  /// **Cancellation:**
  /// Each new settings change cancels the previous pending commit, restarting the 500ms timer.
  /// This ensures only the final state is committed after user stops editing.
  private func scheduleSettingsCommit() {
    commitTask?.cancel()
    commitTask = Task { @MainActor [weak self] in
      guard let self else { return }
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }
      self.commitSettingsChange()
    }
  }

  /// Commits user settings changes by creating a new profile version.
  ///
  /// **Bidirectional Sync: MeterSettings → Profile**
  /// This is one half of the sync mechanism. When users edit settings in the UI,
  /// those changes flow through this function to create a new versioned profile.
  ///
  /// **Change Detection:**
  /// Compares current settings against the active profile's settings. If identical,
  /// no new version is created (prevents duplicate profiles).
  ///
  /// **Profile Versioning:**
  /// - Each settings change creates a NEW profile with effectiveFrom = now
  /// - Original profiles are preserved (maintains history)
  /// - activeProfile() uses effectiveFrom to select the most recent applicable version
  ///
  /// **Why version profiles instead of mutating?**
  /// - Preserves catalog profiles unchanged (can revert to defaults)
  /// - Maintains history of settings changes over time
  /// - Enables future features: profile history viewer, revert to previous settings
  ///
  /// **Example flow:**
  /// 1. User opens app → syncSettingsFromActiveProfile() loads Bengaluru defaults
  /// 2. User changes base fare from ₹25 to ₹30 → settings.didSet fires
  /// 3. scheduleSettingsCommit() debounces for 500ms
  /// 4. commitSettingsChange() creates new profile: "Bengaluru (effective now)"
  /// 5. scheduleSave() persists the new profile
  private func commitSettingsChange() {
    let cityId = effectiveCityId
    let activeProfile = activeProfile(for: cityId, on: Date()) ?? FareCatalog.defaultProfile
    let activeSettings = MeterSettings(profile: activeProfile)

    // Skip commit if settings haven't actually changed
    guard activeSettings != settings else { return }

    let effectiveFrom = Date()
    let newProfile = CityFareProfile(
      id: UUID().uuidString,
      cityId: cityId,
      name: activeProfile.name,
      vehicleType: activeProfile.vehicleType,
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

  /// Syncs MeterSettings from the active profile for the selected city.
  ///
  /// **Bidirectional Sync: Profile → MeterSettings**
  /// This is the other half of the sync mechanism. When the selected city changes
  /// or when loading data, this updates the observable MeterSettings to reflect
  /// the active profile's configuration.
  ///
  /// **When it's called:**
  /// - load() after migrations complete
  /// - selectCity() when user switches cities
  /// - resetToDefaults() after resetting profiles
  /// - addCity() after adding a custom city
  /// - fallbackToDefaultCity() after deleting current city
  ///
  /// **isSyncingFromProfile flag:**
  /// Critical for preventing infinite loops. Without this flag:
  /// 1. syncSettingsFromActiveProfile() updates settings
  /// 2. settings.didSet triggers scheduleSettingsCommit()
  /// 3. commitSettingsChange() creates new profile
  /// 4. New profile triggers another sync → infinite loop
  ///
  /// The flag breaks the cycle by suppressing didSet during profile→settings sync.
  ///
  /// **Commit task cancellation:**
  /// Cancels any pending settings commits because we're loading fresh data from profiles.
  /// This prevents race conditions where a pending commit overwrites the newly loaded settings.
  ///
  /// **Active profile selection:**
  /// Uses activeProfile() to select the most recent profile for the city that's
  /// effective as of now (based on effectiveFrom timestamps).
  private func syncSettingsFromActiveProfile() {
    commitTask?.cancel()
    let cityId = effectiveCityId
    let activeProfile = activeProfile(for: cityId, on: Date()) ?? FareCatalog.defaultProfile
    let newSettings = MeterSettings(profile: activeProfile)

    // Set flag to prevent settings.didSet from triggering commitSettingsChange()
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
