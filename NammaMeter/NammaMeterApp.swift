import SwiftUI

@main
struct NammaMeterApp: App {
  @State private var container: AppContainer

  init() {
    if TestEnvironment.shouldResetState {
      try? FileManager.default.removeItem(at: SettingsStore.defaultURL)
      try? FileManager.default.removeItem(at: TripStore.defaultURL)
    }
    _container = State(initialValue: AppContainer())
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(container)
    }
  }
}
