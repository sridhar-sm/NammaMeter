import SwiftUI

@main
struct NammaMeterApp: App {
  @State private var container = AppContainer()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(container)
    }
  }
}
