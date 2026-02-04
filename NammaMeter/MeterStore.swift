import CoreLocation
import Foundation
import Observation

enum TripMeterState {
  case forHire
  case inProgress
  case complete
}

// MARK: - Location Provider Protocol

protocol LocationProviding: AnyObject {
  var authorizationStatus: CLAuthorizationStatus { get }
  var delegate: CLLocationManagerDelegate? { get set }
  var activityType: CLActivityType { get set }
  var desiredAccuracy: CLLocationAccuracy { get set }
  var distanceFilter: CLLocationDistance { get set }
  var pausesLocationUpdatesAutomatically: Bool { get set }
  var allowsBackgroundLocationUpdates: Bool { get set }
  var showsBackgroundLocationIndicator: Bool { get set }

  func requestWhenInUseAuthorization()
  func requestAlwaysAuthorization()
  func startUpdatingLocation()
  func stopUpdatingLocation()
}

extension CLLocationManager: LocationProviding {}

final class NoopLocationProvider: LocationProviding {
  var authorizationStatus: CLAuthorizationStatus = .notDetermined
  var delegate: CLLocationManagerDelegate?
  var activityType: CLActivityType = .other
  var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
  var distanceFilter: CLLocationDistance = kCLLocationAccuracyBest
  var pausesLocationUpdatesAutomatically: Bool = true
  var allowsBackgroundLocationUpdates: Bool = false
  var showsBackgroundLocationIndicator: Bool = false

  func requestWhenInUseAuthorization() {}
  func requestAlwaysAuthorization() {}
  func startUpdatingLocation() {}
  func stopUpdatingLocation() {}
}

@MainActor
@Observable
final class MeterStore: NSObject, @preconcurrency CLLocationManagerDelegate {
  private(set) var stateMachine = TripStateMachine()
  private(set) var metrics = TripMetrics()
  var fare: Double = 0
  var points: [TripPoint] = []
  var currentSpeedKph: Double = 0
  var isWaiting = false
  var locationError: String?
  var conditions: TripConditions = .clear {
    didSet {
      guard let currentSettings else { return }
      multiplier = conditions.multiplier(using: currentSettings)
      recalcFare()
    }
  }

  var isOnTrip: Bool { stateMachine.isOnTrip }
  var tripState: TripMeterState { stateMachine.tripState }
  var distanceMeters: Double { metrics.distanceMeters }
  var elapsed: TimeInterval { metrics.elapsedSeconds }
  var waitingDuration: TimeInterval { metrics.waitingSeconds }

  @ObservationIgnored private let locationManager: LocationProviding
  @ObservationIgnored private let permissionCoordinator: LocationPermissionCoordinator
  @ObservationIgnored private var tickTask: Task<Void, Never>?
  @ObservationIgnored private var isUpdatingLocation = false
  @ObservationIgnored private let clock = ContinuousClock()
  @ObservationIgnored private var lastLocation: CLLocation?
  @ObservationIgnored private var currentSettings: MeterSettings?
  @ObservationIgnored private var rateSnapshot: RateSnapshot?
  @ObservationIgnored private var multiplier: Double = 1
  @ObservationIgnored private var waitingStartedAt: Date?
  @ObservationIgnored private var waitingAccumulated: TimeInterval = 0
  @ObservationIgnored private var fareCalculator: FareCalculator?

  override convenience init() {
    if TestEnvironment.isRunningTests {
      self.init(locationProvider: NoopLocationProvider())
    } else {
      self.init(locationProvider: CLLocationManager())
    }
  }

  init(locationProvider: LocationProviding) {
    locationManager = locationProvider
    permissionCoordinator = LocationPermissionCoordinator(locationProvider: locationProvider)
    super.init()
    locationManager.delegate = self
    locationManager.activityType = .automotiveNavigation
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 8
    locationManager.pausesLocationUpdatesAutomatically = false
  }

  func requestAuthorization() {
    permissionCoordinator.refreshAuthorizationStatus()
    permissionCoordinator.requestWhenInUseIfNeeded()
  }

  func requestAlwaysAuthorization() {
    permissionCoordinator.requestAlwaysAuthorization()
  }

  func startTrip(settings: MeterSettings, cityId: String? = nil, cityName: String? = nil) {
    guard tripState == .forHire else { return }
    currentSettings = settings
    rateSnapshot = RateSnapshot(settings: settings, cityId: cityId, cityName: cityName)
    fareCalculator = FareCalculator(settings: settings)

    metrics = TripMetrics()
    points = []
    currentSpeedKph = 0
    isWaiting = false
    waitingAccumulated = 0
    waitingStartedAt = nil
    lastLocation = nil
    locationError = nil

    let startTime = Date()
    stateMachine.startTrip(startTime: startTime)
    permissionCoordinator.updateTripState(isOnTrip: true)

    refreshTimeBasedConditions(reference: startTime)
    multiplier = conditions.multiplier(using: settings)
    fare = settings.minFare
    recalcFare()

    requestAuthorization()
    if isAuthorizedForLocationUpdates {
      startLocationUpdates()
    }
    updateBackgroundLocationState()
    startTicking()
  }

  func stopTrip(tripStore: TripStore) {
    guard isOnTrip else { return }
    stopWaiting()
    stopLocationUpdates()
    stopTicking()

    let endDate = Date()
    let snapshot = rateSnapshot ?? RateSnapshot(settings: currentSettings ?? .bengaluruDefault)
    let startDate = stateMachine.startTime ?? endDate
    let trip = Trip(
      id: UUID(),
      startDate: startDate,
      endDate: endDate,
      distanceMeters: metrics.distanceMeters,
      duration: metrics.elapsedSeconds,
      fare: fare,
      points: points,
      conditions: conditions,
      rateSnapshot: snapshot,
      multiplier: multiplier,
      waitingDuration: metrics.waitingSeconds
    )

    stateMachine.completeTrip(trip: trip)
    permissionCoordinator.updateTripState(isOnTrip: false)
    updateBackgroundLocationState()

    tripStore.add(trip)
    Task { await tripStore.resolveStartLocation(for: trip) }
    fareCalculator = nil
    currentSettings = nil
  }

  func resetToForHire() {
    guard tripState == .complete else { return }
    stateMachine.resetToForHire()
    permissionCoordinator.updateTripState(isOnTrip: false)
    metrics = metrics.reset()
    points.removeAll()
    fare = 0
    currentSpeedKph = 0
    isWaiting = false
    waitingAccumulated = 0
    waitingStartedAt = nil
    lastLocation = nil
    fareCalculator = nil
    currentSettings = nil
    rateSnapshot = nil
    multiplier = 1
    locationError = nil
  }

  private func startTicking() {
    tickTask?.cancel()
    tickTask = Task { @MainActor [weak self] in
      guard let self else { return }
      while !Task.isCancelled, self.isOnTrip {
        self.tick()
        try? await clock.sleep(for: .seconds(1))
      }
    }
  }

  private func stopTicking() {
    tickTask?.cancel()
    tickTask = nil
  }

  private func startLocationUpdates() {
    guard !isUpdatingLocation else { return }
    isUpdatingLocation = true
    locationManager.startUpdatingLocation()
  }

  private func stopLocationUpdates() {
    guard isUpdatingLocation else { return }
    isUpdatingLocation = false
    locationManager.stopUpdatingLocation()
  }

  private func tick() {
    guard isOnTrip else { return }
    let now = Date()
    refreshTimeBasedConditions(reference: now)
    updateWaitingDuration(now)
    if let startDate = stateMachine.startTime {
      metrics.setElapsedTime(now.timeIntervalSince(startDate))
    }
    recalcFare()
  }

  private func recalcFare() {
    guard let settings = currentSettings else { return }
    let calculator = fareCalculator ?? FareCalculator(settings: settings)
    fare = calculator.calculateFare(
      distanceKm: metrics.distanceKm,
      elapsedTime: metrics.elapsedSeconds,
      waitingTime: metrics.waitingSeconds,
      isNight: conditions.isNight
    )
  }

  func calculateWaitingCharge(
    waitingDuration: TimeInterval,
    freeWaitMinutes: Double,
    waitIntervalMinutes: Double,
    waitIntervalCharge: Double
  ) -> Double {
    FareCalculator.calculateWaitingCharge(
      waitingDuration: waitingDuration,
      freeWaitMinutes: freeWaitMinutes,
      waitIntervalMinutes: waitIntervalMinutes,
      waitIntervalCharge: waitIntervalCharge
    )
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    permissionCoordinator.handleAuthorizationChange(manager.authorizationStatus)
    if isOnTrip {
      if isAuthorizedForLocationUpdates {
        startLocationUpdates()
      } else {
        stopLocationUpdates()
      }
      updateBackgroundLocationState()
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationError = error.localizedDescription
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    handleLocation(location)
  }

  private func handleLocation(_ location: CLLocation) {
    guard isOnTrip else { return }
    guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 40 else { return }
    processLocation(location)
  }

  /// Process a location update. Exposed for testing with mock location providers.
  func processLocation(_ location: CLLocation) {
    guard isOnTrip else { return }

    currentSpeedKph = max(location.speed, 0) * 3.6
    let point = TripPoint(location: location)
    points.append(point)

    if let lastLocation {
      let delta = location.distance(from: lastLocation)
      if isWaiting && (location.speed >= 1.0 || delta > 8) {
        stopWaiting()
      }
      if delta > 2 {
        metrics.addDistance(delta)
      }
    }
    lastLocation = location
    recalcFare()
  }

  func toggleWaiting() {
    guard isOnTrip else { return }
    isWaiting ? stopWaiting() : startWaiting()
  }

  private func startWaiting() {
    guard isOnTrip, !isWaiting else { return }
    isWaiting = true
    waitingStartedAt = Date()
  }

  private func stopWaiting() {
    guard isWaiting else { return }
    if let waitingStartedAt {
      waitingAccumulated += Date().timeIntervalSince(waitingStartedAt)
    }
    waitingStartedAt = nil
    isWaiting = false
    metrics.setWaitingTime(waitingAccumulated)
  }

  private func updateWaitingDuration(_ now: Date) {
    if isWaiting, let waitingStartedAt {
      metrics.setWaitingTime(waitingAccumulated + now.timeIntervalSince(waitingStartedAt))
    } else {
      metrics.setWaitingTime(waitingAccumulated)
    }
  }

  func refreshTimeBasedConditions(reference: Date = Date()) {
    let settings = currentSettings ?? MeterSettings.bengaluruDefault
    let nightNow = settings.isNight(at: reference)
    if conditions.isNight != nightNow {
      conditions.isNight = nightNow
    }
  }

  private func updateBackgroundLocationState() {
    let shouldEnable = isOnTrip && authorizationStatus == .authorizedAlways && hasBackgroundLocationMode
    if locationManager.allowsBackgroundLocationUpdates != shouldEnable {
      locationManager.allowsBackgroundLocationUpdates = shouldEnable
    }
    if locationManager.showsBackgroundLocationIndicator != shouldEnable {
      locationManager.showsBackgroundLocationIndicator = shouldEnable
    }
  }

  private var hasBackgroundLocationMode: Bool {
    guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else { return false }
    return modes.contains("location")
  }

  private var isAuthorizedForLocationUpdates: Bool {
    switch authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      return true
    default:
      return false
    }
  }

  private var authorizationStatus: CLAuthorizationStatus {
    permissionCoordinator.authorizationStatus
  }

  var locationPermissionCoordinator: LocationPermissionCoordinator {
    permissionCoordinator
  }
}
