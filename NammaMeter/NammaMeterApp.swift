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
      if TestEnvironment.isRunningHostedUnitTests {
        UnitTestHostView()
      } else {
        ContentView()
          .environment(container)
          .modifier(ScreenAwakeSyncModifier(
            screenAwakeManager: container.screenAwakeManager,
            settingsStore: container.settingsStore,
            meterStore: container.meterStore
          ))
      }
    }
  }
}

private struct UnitTestHostView: View {
  var body: some View {
    Color.clear
      .ignoresSafeArea()
  }
}

struct ScreenAwakeSyncModifier: ViewModifier {
  let screenAwakeManager: ScreenAwakeManager
  let settingsStore: SettingsStore
  let meterStore: MeterStore

  func body(content: Content) -> some View {
    content
      .onChange(of: settingsStore.settings.keepScreenAwakeDuringTrip) { _, newValue in
        screenAwakeManager.isEnabled = newValue
      }
      .onChange(of: meterStore.tripState) { _, newState in
        screenAwakeManager.tripState = newState
      }
      .onAppear {
        screenAwakeManager.isEnabled = settingsStore.settings.keepScreenAwakeDuringTrip
        screenAwakeManager.tripState = meterStore.tripState
      }
  }
}
