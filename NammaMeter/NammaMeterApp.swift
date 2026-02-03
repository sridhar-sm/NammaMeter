import SwiftUI

@main
struct NammaMeterApp: App {
  @State private var settingsStore = SettingsStore()
  @State private var tripStore = TripStore()
  @State private var meterStore = MeterStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(settingsStore)
        .environment(tripStore)
        .environment(meterStore)
    }
  }
}
