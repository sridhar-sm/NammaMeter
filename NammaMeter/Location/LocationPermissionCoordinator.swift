import CoreLocation
import Observation

@MainActor
@Observable
final class LocationPermissionCoordinator {
  private(set) var authorizationStatus: CLAuthorizationStatus
  var showLocationDeniedAlert = false
  var showAlwaysPrompt = false

  @ObservationIgnored private let locationProvider: LocationProviding
  @ObservationIgnored private var hasPromptedForAlways = false
  @ObservationIgnored private var isOnTrip = false

  init(locationProvider: LocationProviding) {
    self.locationProvider = locationProvider
    let status = locationProvider.authorizationStatus
    authorizationStatus = status
    showLocationDeniedAlert = status == .denied || status == .restricted
  }

  func refreshAuthorizationStatus() {
    handleAuthorizationChange(locationProvider.authorizationStatus)
  }

  func requestWhenInUseIfNeeded() {
    guard authorizationStatus == .notDetermined else { return }
    locationProvider.requestWhenInUseAuthorization()
  }

  func requestAlwaysAuthorization() {
    guard authorizationStatus == .authorizedWhenInUse else { return }
    locationProvider.requestAlwaysAuthorization()
  }

  func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
    authorizationStatus = status
    showLocationDeniedAlert = status == .denied || status == .restricted
    if status == .authorizedAlways {
      showAlwaysPrompt = false
    }
    evaluateAlwaysPromptIfNeeded()
  }

  func updateTripState(isOnTrip: Bool) {
    self.isOnTrip = isOnTrip
    if isOnTrip {
      hasPromptedForAlways = false
      evaluateAlwaysPromptIfNeeded()
    } else {
      showAlwaysPrompt = false
    }
  }

  func dismissDeniedAlert() {
    showLocationDeniedAlert = false
  }

  func dismissAlwaysPrompt() {
    showAlwaysPrompt = false
  }

  private func evaluateAlwaysPromptIfNeeded() {
    guard isOnTrip else { return }
    guard authorizationStatus == .authorizedWhenInUse else { return }
    guard !hasPromptedForAlways else { return }
    hasPromptedForAlways = true
    showAlwaysPrompt = true
  }
}
