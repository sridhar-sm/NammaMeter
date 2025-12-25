import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
  @Published var settings: MeterSettings {
    didSet {
      guard isLoaded else { return }
      save()
    }
  }

  private let fileURL: URL
  private var isLoaded = false

  init(fileURL: URL = SettingsStore.defaultURL) {
    self.fileURL = fileURL
    self.settings = MeterSettings.bengaluruDefault
    load()
    isLoaded = true
  }

  func resetToDefaults() {
    settings = MeterSettings.bengaluruDefault
  }

  private func load() {
    guard let data = try? Data(contentsOf: fileURL) else { return }
    guard let decoded = try? JSONDecoder().decode(MeterSettings.self, from: data) else { return }
    settings = decoded
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(settings) else { return }
    try? data.write(to: fileURL, options: [.atomic])
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("settings.json")
  }
}
