import CoreLocation
import Foundation
import XCTest
@testable import NammaMeter

// MARK: - Mock Location Provider

final class MockLocationProvider: LocationProviding, @unchecked Sendable {
  nonisolated(unsafe) var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
  nonisolated(unsafe) weak var delegate: CLLocationManagerDelegate?
  nonisolated(unsafe) var activityType: CLActivityType = .other
  nonisolated(unsafe) var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
  nonisolated(unsafe) var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
  nonisolated(unsafe) var pausesLocationUpdatesAutomatically: Bool = false
  nonisolated(unsafe) var allowsBackgroundLocationUpdates: Bool = false
  nonisolated(unsafe) var showsBackgroundLocationIndicator: Bool = false

  nonisolated(unsafe) var didRequestWhenInUseAuthorization = false
  nonisolated(unsafe) var didRequestAlwaysAuthorization = false
  nonisolated(unsafe) var didStartUpdatingLocation = false
  nonisolated(unsafe) var didStopUpdatingLocation = false

  func requestWhenInUseAuthorization() {
    didRequestWhenInUseAuthorization = true
  }

  func requestAlwaysAuthorization() {
    didRequestAlwaysAuthorization = true
  }

  func startUpdatingLocation() {
    didStartUpdatingLocation = true
  }

  func stopUpdatingLocation() {
    didStopUpdatingLocation = true
  }

  func reset() {
    didRequestWhenInUseAuthorization = false
    didRequestAlwaysAuthorization = false
    didStartUpdatingLocation = false
    didStopUpdatingLocation = false
  }
}

// MARK: - MeterStore Tests

@MainActor
final class MeterStoreTests: XCTestCase {

  private var mockLocationProvider: MockLocationProvider!
  private var meterStore: MeterStore!
  private var tripStore: TripStore!

  override func setUp() async throws {
    mockLocationProvider = MockLocationProvider()
    meterStore = MeterStore(locationProvider: mockLocationProvider)
    let tempURL = try TestHelpers.makeTempURL(filename: "trips.json")
    tripStore = TripStore(fileURL: tempURL)
    // Wait for TripStore to initialize
    await TestHelpers.waitForTripStoreLoad(tripStore)
  }

  // MARK: - Trip Lifecycle Tests

  func testInitialState() {
    XCTAssertFalse(meterStore.isOnTrip)
    XCTAssertEqual(meterStore.tripState, .forHire)
    XCTAssertEqual(meterStore.distanceMeters, 0)
    XCTAssertEqual(meterStore.elapsed, 0)
    XCTAssertEqual(meterStore.fare, 0)
    XCTAssertFalse(meterStore.isWaiting)
    XCTAssertEqual(meterStore.waitingDuration, 0)
  }

  func testStartTripInitializesState() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)

    XCTAssertTrue(meterStore.isOnTrip)
    XCTAssertEqual(meterStore.tripState, .inProgress)
    XCTAssertEqual(meterStore.fare, settings.minFare)
    XCTAssertEqual(meterStore.distanceMeters, 0)
    XCTAssertFalse(meterStore.isWaiting)
  }

  func testStartTripWithCityInfo() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")

    XCTAssertTrue(meterStore.isOnTrip)
    XCTAssertEqual(meterStore.tripState, .inProgress)
  }

  func testStartTripWhileOnTripIsNoOp() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    let initialFare = meterStore.fare

    // Modify settings to verify it's not reapplied
    var newSettings = settings
    newSettings.minFare = 100

    meterStore.startTrip(settings: newSettings)

    XCTAssertEqual(meterStore.fare, initialFare)
  }

  func testStopTripCreatesTrip() async throws {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    XCTAssertTrue(tripStore.trips.isEmpty)

    meterStore.stopTrip(tripStore: tripStore)

    // Wait for trip to be added
    try await Task.sleep(for: .milliseconds(100))

    XCTAssertFalse(meterStore.isOnTrip)
    XCTAssertEqual(meterStore.tripState, .complete)
    XCTAssertEqual(tripStore.trips.count, 1)

    let savedTrip = tripStore.trips.first!
    XCTAssertEqual(savedTrip.fare, settings.minFare)
    XCTAssertEqual(savedTrip.distanceMeters, 0)
  }

  func testStopTripWhileNotOnTripIsNoOp() {
    XCTAssertFalse(meterStore.isOnTrip)

    meterStore.stopTrip(tripStore: tripStore)

    XCTAssertFalse(meterStore.isOnTrip)
    XCTAssertTrue(tripStore.trips.isEmpty)
  }

  func testResetToForHire() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    meterStore.stopTrip(tripStore: tripStore)
    XCTAssertEqual(meterStore.tripState, .complete)

    meterStore.resetToForHire()

    XCTAssertEqual(meterStore.tripState, .forHire)
  }

  func testResetToForHireWhileInProgressIsNoOp() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    XCTAssertEqual(meterStore.tripState, .inProgress)

    meterStore.resetToForHire()

    XCTAssertEqual(meterStore.tripState, .inProgress)
  }

  // MARK: - Fare Calculation Tests

  func testFareCalculationWithinIncludedKm() {
    var settings = MeterSettings.bengaluruDefault
    settings.baseFare = 36
    settings.includedKm = 2.0
    settings.perKmRate = 18
    settings.minFare = 36

    meterStore.startTrip(settings: settings)

    // Ensure it's day time for consistent fare calculation
    var dayComponents = DateComponents()
    dayComponents.year = 2026
    dayComponents.month = 2
    dayComponents.day = 3
    dayComponents.hour = 10
    let dayDate = Calendar.autoupdatingCurrent.date(from: dayComponents)!
    meterStore.refreshTimeBasedConditions(reference: dayDate)

    // Process location within included km (1.5 km)
    let start = CLLocation(latitude: 12.9716, longitude: 77.5946)
    meterStore.processLocation(start)

    // Move ~1.5km (roughly 0.0135 degrees latitude)
    let end = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9851, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      timestamp: Date()
    )
    meterStore.processLocation(end)

    // Fare should still be minimum (within included km)
    XCTAssertEqual(meterStore.fare, settings.minFare)
  }

  func testFareCalculationBeyondIncludedKm() {
    var settings = MeterSettings.bengaluruDefault
    settings.baseFare = 36
    settings.includedKm = 2.0
    settings.perKmRate = 18
    settings.minFare = 36

    meterStore.startTrip(settings: settings)

    // Process location to simulate 5km trip
    let start = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      timestamp: Date()
    )
    meterStore.processLocation(start)

    // Move ~5km (roughly 0.045 degrees latitude in Bengaluru)
    let end = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 13.0166, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      timestamp: Date()
    )
    meterStore.processLocation(end)

    // Fare should be: baseFare + (5 - 2) * perKmRate = 36 + 3 * 18 = 90
    // But actual distance calculation may vary
    XCTAssertGreaterThan(meterStore.fare, settings.minFare)
    XCTAssertGreaterThan(meterStore.distanceMeters, 2000) // Should be beyond included km
  }

  func testFareNeverBelowMinimum() {
    var settings = MeterSettings.bengaluruDefault
    settings.minFare = 50
    settings.baseFare = 36

    meterStore.startTrip(settings: settings)

    // Even with baseFare < minFare, fare should be minFare
    XCTAssertEqual(meterStore.fare, settings.minFare)
  }

  func testNightMultiplierApplied() {
    var settings = MeterSettings.bengaluruDefault
    settings.baseFare = 36
    settings.minFare = 36
    settings.nightMultiplier = 1.5
    settings.nightStartHour = 22
    settings.nightEndHour = 5

    meterStore.startTrip(settings: settings)

    // First ensure day time to reset state
    var dayComponents = DateComponents()
    dayComponents.year = 2026
    dayComponents.month = 2
    dayComponents.day = 3
    dayComponents.hour = 10
    let dayDate = Calendar.autoupdatingCurrent.date(from: dayComponents)!
    meterStore.refreshTimeBasedConditions(reference: dayDate)
    XCTAssertFalse(meterStore.conditions.isNight)
    XCTAssertEqual(meterStore.fare, 36)

    // Now switch to night time (23:00)
    var nightComponents = DateComponents()
    nightComponents.year = 2026
    nightComponents.month = 2
    nightComponents.day = 3
    nightComponents.hour = 23
    let nightDate = Calendar.autoupdatingCurrent.date(from: nightComponents)!
    meterStore.refreshTimeBasedConditions(reference: nightDate)

    // Fare should be minFare * nightMultiplier = 36 * 1.5 = 54
    XCTAssertTrue(meterStore.conditions.isNight)
    XCTAssertEqual(meterStore.fare, 54)
  }

  // MARK: - Waiting State Tests

  func testToggleWaitingStartsWaiting() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    XCTAssertFalse(meterStore.isWaiting)

    meterStore.toggleWaiting()

    XCTAssertTrue(meterStore.isWaiting)
  }

  func testToggleWaitingStopsWaiting() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    meterStore.toggleWaiting()
    XCTAssertTrue(meterStore.isWaiting)

    meterStore.toggleWaiting()

    XCTAssertFalse(meterStore.isWaiting)
  }

  func testToggleWaitingWhileNotOnTripIsNoOp() {
    XCTAssertFalse(meterStore.isOnTrip)
    XCTAssertFalse(meterStore.isWaiting)

    meterStore.toggleWaiting()

    XCTAssertFalse(meterStore.isWaiting)
  }

  func testWaitingStopsOnMovement() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)

    // Start waiting
    meterStore.toggleWaiting()
    XCTAssertTrue(meterStore.isWaiting)

    // Process initial location
    let start = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      course: 0,
      speed: 0,
      timestamp: Date()
    )
    meterStore.processLocation(start)
    XCTAssertTrue(meterStore.isWaiting)

    // Process location with movement (speed > 1 m/s)
    let moving = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9720, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      course: 0,
      speed: 5.0, // 5 m/s = 18 km/h
      timestamp: Date()
    )
    meterStore.processLocation(moving)

    XCTAssertFalse(meterStore.isWaiting, "Waiting should stop when vehicle moves")
  }

  // MARK: - Time-Based Conditions Tests

  func testNightConditionUpdates() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)

    // Day time (10:00)
    var dayComponents = DateComponents()
    dayComponents.year = 2026
    dayComponents.month = 2
    dayComponents.day = 3
    dayComponents.hour = 10
    let dayDate = Calendar.autoupdatingCurrent.date(from: dayComponents)!

    meterStore.refreshTimeBasedConditions(reference: dayDate)
    XCTAssertFalse(meterStore.conditions.isNight)

    // Night time (23:00)
    var nightComponents = DateComponents()
    nightComponents.year = 2026
    nightComponents.month = 2
    nightComponents.day = 3
    nightComponents.hour = 23
    let nightDate = Calendar.autoupdatingCurrent.date(from: nightComponents)!

    meterStore.refreshTimeBasedConditions(reference: nightDate)
    XCTAssertTrue(meterStore.conditions.isNight)
  }

  // MARK: - Waiting Charge Calculation Tests

  func testCalculateWaitingChargeWithinFreeTime() {
    let charge = meterStore.calculateWaitingCharge(
      waitingDuration: 4 * 60, // 4 minutes
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    )

    XCTAssertEqual(charge, 0)
  }

  func testCalculateWaitingChargeOneInterval() {
    let charge = meterStore.calculateWaitingCharge(
      waitingDuration: 10 * 60, // 10 minutes (5 free + 5 chargeable = 1 interval)
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    )

    XCTAssertEqual(charge, 10) // 1 interval * 10
  }

  func testCalculateWaitingChargeMultipleIntervals() {
    let charge = meterStore.calculateWaitingCharge(
      waitingDuration: 35 * 60, // 35 minutes (5 free + 30 chargeable = 2 intervals)
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    )

    XCTAssertEqual(charge, 20) // 2 intervals * 10
  }

  func testCalculateWaitingChargeZeroInterval() {
    let charge = meterStore.calculateWaitingCharge(
      waitingDuration: 30 * 60,
      freeWaitMinutes: 5,
      waitIntervalMinutes: 0, // Zero interval
      waitIntervalCharge: 10
    )

    XCTAssertEqual(charge, 0)
  }

  // MARK: - Location Processing Tests

  func testLocationProcessingAddsPoints() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    XCTAssertTrue(meterStore.points.isEmpty)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      timestamp: Date()
    )
    meterStore.processLocation(location)

    XCTAssertEqual(meterStore.points.count, 1)
  }

  func testLocationProcessingUpdatesSpeed() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    XCTAssertEqual(meterStore.currentSpeedKph, 0)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      course: 0,
      speed: 10, // 10 m/s = 36 km/h
      timestamp: Date()
    )
    meterStore.processLocation(location)

    XCTAssertEqual(meterStore.currentSpeedKph, 36, accuracy: 0.1)
  }

  func testLocationProcessingWhenNotOnTripIsNoOp() {
    XCTAssertFalse(meterStore.isOnTrip)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
      altitude: 0,
      horizontalAccuracy: 10,
      verticalAccuracy: 10,
      timestamp: Date()
    )
    meterStore.processLocation(location)

    XCTAssertTrue(meterStore.points.isEmpty)
  }

  // MARK: - Authorization Tests

  func testRequestAuthorizationWhenNotDetermined() async throws {
    mockLocationProvider.authorizationStatus = .notDetermined
    let store = MeterStore(locationProvider: mockLocationProvider)

    store.requestAuthorization()

    try await Task.sleep(for: .milliseconds(50))
    XCTAssertTrue(mockLocationProvider.didRequestWhenInUseAuthorization)
  }

  func testRequestAuthorizationWhenAlreadyAuthorized() async throws {
    mockLocationProvider.authorizationStatus = .authorizedWhenInUse
    let store = MeterStore(locationProvider: mockLocationProvider)

    store.requestAuthorization()

    try await Task.sleep(for: .milliseconds(50))
    XCTAssertFalse(mockLocationProvider.didRequestWhenInUseAuthorization)
  }

  func testStartTripRequestsLocationUpdates() async throws {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)

    try await Task.sleep(for: .milliseconds(50))
    XCTAssertTrue(mockLocationProvider.didStartUpdatingLocation)
  }

  func testStopTripStopsLocationUpdates() async throws {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings)
    try await Task.sleep(for: .milliseconds(50))

    mockLocationProvider.reset()
    meterStore.stopTrip(tripStore: tripStore)

    try await Task.sleep(for: .milliseconds(50))
    XCTAssertTrue(mockLocationProvider.didStopUpdatingLocation)
  }
}
