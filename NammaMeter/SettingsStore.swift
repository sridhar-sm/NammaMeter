import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
  var settings: MeterSettings {
    didSet {
      guard isLoaded else { return }
      saveTask?.cancel()
      saveTask = Task { await save() }
    }
  }

  @ObservationIgnored private let persistence: SettingsPersistence
  @ObservationIgnored private var isLoaded = false
  @ObservationIgnored private var saveTask: Task<Void, Never>?

  init(fileURL: URL = SettingsStore.defaultURL) {
    self.persistence = SettingsPersistence(url: fileURL)
    self.settings = MeterSettings.bengaluruDefault
    Task { await load() }
  }

  func resetToDefaults() {
    settings = MeterSettings.bengaluruDefault
  }

  private func load() async {
    if let decoded = await persistence.load() {
      settings = decoded
    }
    isLoaded = true
  }

  private func save() async {
    guard !Task.isCancelled, isLoaded else { return }
    await persistence.save(settings)
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("settings.json")
  }
}

private actor SettingsPersistence {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func load() -> MeterSettings? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(MeterSettings.self, from: data)
  }

  func save(_ settings: MeterSettings) {
    guard let data = try? JSONEncoder().encode(settings) else { return }
    try? data.write(to: url, options: [.atomic])
  }
}
