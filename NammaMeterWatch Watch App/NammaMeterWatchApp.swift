import SwiftUI

@main
struct NammaMeterWatchApp: App {
  @State private var connectivityService = WatchConnectivityService()
  @State private var tripStore = WatchTripStore()

  var body: some Scene {
    WindowGroup {
      WatchContentView()
        .environment(tripStore)
        .environment(connectivityService)
        .onAppear {
          connectivityService.tripStore = tripStore
        }
    }
  }
}
