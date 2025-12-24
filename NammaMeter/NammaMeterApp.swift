import SwiftUI

@main
struct NammaMeterApp: App {
  @StateObject private var settingsStore = SettingsStore()
  @StateObject private var tripStore = TripStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(settingsStore)
        .environmentObject(tripStore)
    }
  }
}
