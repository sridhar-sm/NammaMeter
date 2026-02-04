import CoreLocation
import XCTest
@testable import NammaMeter

// MARK: - Stub Location Provider

final class StubLocationProvider: LocationProviding {
  var authorizationStatus: CLAuthorizationStatus
  weak var delegate: CLLocationManagerDelegate?
  var activityType: CLActivityType = .other
  var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
  var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
  var pausesLocationUpdatesAutomatically: Bool = false
  var allowsBackgroundLocationUpdates: Bool = false
  var showsBackgroundLocationIndicator: Bool = false

  var didRequestWhenInUseAuthorization = false
  var didRequestAlwaysAuthorization = false

  init(status: CLAuthorizationStatus) {
    authorizationStatus = status
  }

  func requestWhenInUseAuthorization() {
    didRequestWhenInUseAuthorization = true
  }

  func requestAlwaysAuthorization() {
    didRequestAlwaysAuthorization = true
  }

  func startUpdatingLocation() { }
  func stopUpdatingLocation() { }
}

@MainActor
final class LocationPermissionCoordinatorTests: XCTestCase {
  func testInitialDeniedStatusShowsAlert() {
    let provider = StubLocationProvider(status: .denied)
    let coordinator = LocationPermissionCoordinator(locationProvider: provider)

    XCTAssertEqual(coordinator.authorizationStatus, .denied)
    XCTAssertTrue(coordinator.showLocationDeniedAlert)
  }

  func testRequestWhenInUseIfNeeded() {
    let provider = StubLocationProvider(status: .notDetermined)
    let coordinator = LocationPermissionCoordinator(locationProvider: provider)

    coordinator.requestWhenInUseIfNeeded()

    XCTAssertTrue(provider.didRequestWhenInUseAuthorization)
  }

  func testRequestAlwaysAuthorizationOnlyWhenWhenInUse() {
    let provider = StubLocationProvider(status: .authorizedWhenInUse)
    let coordinator = LocationPermissionCoordinator(locationProvider: provider)

    coordinator.requestAlwaysAuthorization()

    XCTAssertTrue(provider.didRequestAlwaysAuthorization)
  }

  func testHandleAuthorizationChangeSetsDeniedAlert() {
    let provider = StubLocationProvider(status: .notDetermined)
    let coordinator = LocationPermissionCoordinator(locationProvider: provider)

    coordinator.handleAuthorizationChange(.denied)

    XCTAssertEqual(coordinator.authorizationStatus, .denied)
    XCTAssertTrue(coordinator.showLocationDeniedAlert)
  }

  func testTripStartPromptsAlwaysWhenAuthorizedWhenInUse() {
    let provider = StubLocationProvider(status: .authorizedWhenInUse)
    let coordinator = LocationPermissionCoordinator(locationProvider: provider)

    coordinator.updateTripState(isOnTrip: true)

    XCTAssertTrue(coordinator.showAlwaysPrompt)
  }
}
