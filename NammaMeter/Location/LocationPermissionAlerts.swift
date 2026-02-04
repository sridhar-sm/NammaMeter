import SwiftUI
import UIKit

struct LocationPermissionAlerts: ViewModifier {
  @Bindable var coordinator: LocationPermissionCoordinator
  @Environment(\.openURL) private var openURL

  func body(content: Content) -> some View {
    content
      .alert("Location access needed", isPresented: $coordinator.showLocationDeniedAlert) {
        Button("Open Settings") {
          openSettings()
        }
        Button("Not Now", role: .cancel) {
          coordinator.dismissDeniedAlert()
        }
      } message: {
        Text("Enable location to track distance and replay routes.")
      }
      .alert("Enable background tracking", isPresented: $coordinator.showAlwaysPrompt) {
        Button("Enable Always") {
          coordinator.requestAlwaysAuthorization()
          coordinator.dismissAlwaysPrompt()
        }
        Button("Open Settings") {
          openSettings()
        }
        Button("Not Now", role: .cancel) {
          coordinator.dismissAlwaysPrompt()
        }
      } message: {
        Text("Allow Always location access to keep tracking distance when the app is in the background.")
      }
  }

  private func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      openURL(url)
    }
  }
}

extension View {
  func withLocationPermissionHandling(coordinator: LocationPermissionCoordinator) -> some View {
    modifier(LocationPermissionAlerts(coordinator: coordinator))
  }
}
