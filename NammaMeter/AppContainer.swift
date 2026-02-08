import SwiftUI

/// Centralized dependency container for the app's stores.
///
/// Usage in app:
/// ```swift
/// @State private var container = AppContainer()
/// // ...
/// ContentView()
///     .environment(container)
/// ```
///
/// Usage in previews:
/// ```swift
/// ContentView()
///     .environment(AppContainer.preview)
/// ```
@MainActor
@Observable
final class AppContainer {
  let settingsStore: SettingsStore
  let tripStore: TripStore
  let meterStore: MeterStore
  let screenAwakeManager: ScreenAwakeManager

  init(
    settingsStore: SettingsStore = SettingsStore(),
    tripStore: TripStore = TripStore(),
    meterStore: MeterStore = MeterStore(),
    screenAwakeManager: ScreenAwakeManager = ScreenAwakeManager()
  ) {
    self.settingsStore = settingsStore
    self.tripStore = tripStore
    self.meterStore = meterStore
    self.screenAwakeManager = screenAwakeManager
  }
}

// MARK: - Preview Support

extension AppContainer {
  /// Container configured for SwiftUI previews with in-memory stores.
  static var preview: AppContainer {
    AppContainer(
      settingsStore: SettingsStore(fileURL: previewURL(for: "settings")),
      tripStore: TripStore(fileURL: previewURL(for: "trips")),
      meterStore: MeterStore(locationProvider: NoopLocationProvider()),
      screenAwakeManager: ScreenAwakeManager()
    )
  }

  private static func previewURL(for name: String) -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("preview_\(name)_\(UUID().uuidString).json")
  }
}

// MARK: - Environment Integration

extension View {
  /// Injects all stores from the container into the SwiftUI environment.
  ///
  /// This allows views to continue using `@Environment(SettingsStore.self)`
  /// pattern without modification.
  func environment(_ container: AppContainer) -> some View {
    self
      .environment(container.settingsStore)
      .environment(container.tripStore)
      .environment(container.meterStore)
      .environment(container.screenAwakeManager)
  }
}
