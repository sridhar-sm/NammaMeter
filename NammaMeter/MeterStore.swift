import CoreLocation
import Foundation
import Observation
import OSLog

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
  private enum LocationValidation {
    static let maxAcceptedImpliedSpeedKph: Double = 140
    static let maxDisplayedSpeedKph: Double = 140
    static let minDistanceDeltaMeters: CLLocationDistance = 2
    static let observedCadenceValidationThresholdMeters: CLLocationDistance = 5_000
  }

  private(set) var stateMachine = TripStateMachine()
  private(set) var metrics = TripMetrics()
  var fare: Double = 0
  var points: [TripPoint] = []
  var currentSpeedKph: Double = 0
  var isWaiting = false
  var locationError: String?
  var currentRoadName: String = ""
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
  var whatIfResults: [WhatIfResult] = []
  var activeCurrencyCode: String = "INR"

  @ObservationIgnored private let locationManager: LocationProviding
  @ObservationIgnored private let permissionCoordinator: LocationPermissionCoordinator
  @ObservationIgnored private var tickTask: Task<Void, Never>?
  @ObservationIgnored private var isUpdatingLocation = false
  @ObservationIgnored private let clock = ContinuousClock()
  @ObservationIgnored private var lastLocation: CLLocation?
  @ObservationIgnored private var lastLocationObservedAt: Date?
  @ObservationIgnored private var currentSettings: MeterSettings?
  @ObservationIgnored private var rateSnapshot: RateSnapshot?
  @ObservationIgnored private var multiplier: Double = 1
  @ObservationIgnored private var waitingStartedAt: Date?
  @ObservationIgnored private var waitingAccumulated: TimeInterval = 0
  @ObservationIgnored private var fareCalculator: FareCalculator?
  @ObservationIgnored private var currentSurcharges: [FareSurcharge]?
  @ObservationIgnored private var whatIfProfiles: [(WhatIfFavorite, CityFareProfile)] = []
  @ObservationIgnored private var roadGeocodeTask: Task<Void, Never>?
  @ObservationIgnored private var lastRoadGeocodeAt: Date?
  @ObservationIgnored private var lastRoadGeocodeLocation: CLLocation?
  @ObservationIgnored private let roadGeocoder = CLGeocoder()

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

  func startTrip(
    settings: MeterSettings,
    cityId: String? = nil,
    cityName: String? = nil,
    surcharges: [FareSurcharge]? = nil,
    perMinuteWhenSlow: Double? = nil,
    slowSpeedThresholdKph: Double? = nil,
    vehicleType: String? = nil,
    currencyCode: String? = nil,
    whatIfFavorites: [WhatIfFavorite] = [],
    whatIfProfileLookup: ((WhatIfFavorite) -> CityFareProfile?)? = nil
  ) {
    guard tripState == .forHire else { return }
    currentSettings = settings
    currentSurcharges = surcharges
    activeCurrencyCode = currencyCode ?? "INR"
    rateSnapshot = RateSnapshot(
      settings: settings,
      cityId: cityId,
      cityName: cityName,
      vehicleType: vehicleType,
      currencyCode: currencyCode,
      surcharges: surcharges
    )

    if let lookup = whatIfProfileLookup {
      whatIfProfiles = whatIfFavorites.compactMap { fav in
        guard let profile = lookup(fav) else { return nil }
        return (fav, profile)
      }
    } else {
      whatIfProfiles = []
    }
    whatIfResults = []
    fareCalculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: perMinuteWhenSlow,
      slowSpeedThresholdKph: slowSpeedThresholdKph
    )

    metrics = TripMetrics()
    points = []
    currentSpeedKph = 0
    isWaiting = false
    waitingAccumulated = 0
    waitingStartedAt = nil
    lastLocation = nil
    lastLocationObservedAt = nil
    currentRoadName = ""
    lastRoadGeocodeAt = nil
    lastRoadGeocodeLocation = nil
    roadGeocodeTask?.cancel()
    roadGeocoder.cancelGeocode()
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

    Log.trip.info("Trip started: baseFare=\(settings.baseFare), perKm=\(settings.perKmRate), multiplier=\(self.multiplier)")
  }

  func stopTrip(tripStore: TripStore) {
    guard isOnTrip else { return }
    stopWaiting()
    stopLocationUpdates()
    stopTicking()
    currentSpeedKph = 0

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
    currentSurcharges = nil
    whatIfProfiles = []
    whatIfResults = []

    Log.trip.info("Trip completed: fare=₹\(trip.fare, format: .fixed(precision: 2)), distance=\(trip.distanceMeters / 1000, format: .fixed(precision: 2))km, duration=\(trip.duration, format: .fixed(precision: 0))s")
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
    lastLocationObservedAt = nil
    currentRoadName = ""
    lastRoadGeocodeAt = nil
    lastRoadGeocodeLocation = nil
    roadGeocodeTask?.cancel()
    roadGeocoder.cancelGeocode()
    fareCalculator = nil
    currentSettings = nil
    currentSurcharges = nil
    rateSnapshot = nil
    multiplier = 1
    locationError = nil
    whatIfProfiles = []
    whatIfResults = []
    activeCurrencyCode = "INR"

    Log.trip.info("Meter reset to for-hire")
  }

  func switchVehicleType(settingsStore: SettingsStore) {
    guard isOnTrip else { return }
    let newSettings = settingsStore.settings
    let profile = settingsStore.activeProfileForCurrentSelection

    currentSettings = newSettings
    currentSurcharges = profile?.surcharges
    fareCalculator = FareCalculator(
      settings: newSettings,
      perMinuteWhenSlow: profile?.rates.perMinuteWhenSlow,
      slowSpeedThresholdKph: profile?.rates.slowSpeedThresholdKph
    )

    let cityInfo = settingsStore.activeCityInfo
    activeCurrencyCode = profile?.cityKey.currencyCode ?? "INR"
    rateSnapshot = RateSnapshot(
      settings: newSettings,
      cityId: cityInfo.cityId,
      cityName: cityInfo.cityName,
      vehicleType: profile?.vehicleType,
      currencyCode: profile?.cityKey.currencyCode,
      surcharges: profile?.surcharges
    )

    multiplier = conditions.multiplier(using: newSettings)
    recalcFare()

    Log.trip.info("Vehicle type switched mid-trip: \(settingsStore.selectedVehicleType ?? "default")")
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
    let breakdown = calculator.calculateFare(
      distanceKm: metrics.distanceKm,
      elapsedTime: metrics.elapsedSeconds,
      waitingTime: metrics.waitingSeconds,
      currentSpeedKph: currentSpeedKph,
      surcharges: currentSurcharges,
      tripDate: Date(),
      isNight: conditions.isNight
    )
    fare = breakdown.total
    recalcWhatIf()
  }

  private func recalcWhatIf() {
    guard !whatIfProfiles.isEmpty else {
      if !whatIfResults.isEmpty { whatIfResults = [] }
      return
    }
    let now = Date()
    whatIfResults = whatIfProfiles.map { (fav, profile) in
      WhatIfCalculator.calculate(
        favorite: fav,
        profile: profile,
        distanceKm: metrics.distanceKm,
        elapsedTime: metrics.elapsedSeconds,
        waitingTime: metrics.waitingSeconds,
        tripDate: now,
        isNight: conditions.isNight
      )
    }
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
    let status = manager.authorizationStatus
    Log.location.info("Location authorization changed: \(String(describing: status))")
    permissionCoordinator.handleAuthorizationChange(status)
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
    Log.location.error("Location error: \(error.localizedDescription)")
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
    guard isFreshLocation(location) else {
      Log.location.debug("Ignoring cached pre-trip location update")
      return
    }
    let observedAt = Date()
    var derivedSpeedKph: Double?

    if let previousLocation = lastLocation {
      let delta = location.distance(from: previousLocation)
      let observedDelta = lastLocationObservedAt.map { observedAt.timeIntervalSince($0) }
      if isWaiting && (location.speed >= 1.0 || delta > 8) {
        stopWaiting()
      }
      if delta > LocationValidation.minDistanceDeltaMeters {
        guard isPlausibleDistanceJump(delta: delta, from: previousLocation, to: location, observedDelta: observedDelta) else { return }
        metrics.addDistance(delta)
      }

      // Many simulator/route feeds do not provide per-point speed; derive from distance/time when absent.
      if location.speed <= 0 {
        let timestampDelta = location.timestamp.timeIntervalSince(previousLocation.timestamp)
        if timestampDelta > 0 {
          let effectiveDelta = effectiveTimeDelta(
            delta: delta,
            timestampDelta: timestampDelta,
            observedDelta: observedDelta
          )
          let speedKph = (delta / effectiveDelta) * 3.6
          derivedSpeedKph = min(speedKph, LocationValidation.maxDisplayedSpeedKph)
        }
      }
    }

    let reportedSpeedKph = max(location.speed, 0) * 3.6
    currentSpeedKph = min(reportedSpeedKph, LocationValidation.maxDisplayedSpeedKph)
    if currentSpeedKph == 0, let derivedSpeedKph {
      currentSpeedKph = derivedSpeedKph
    }

    let point = TripPoint(location: location)
    points.append(point)
    lastLocation = location
    lastLocationObservedAt = observedAt
    refreshCurrentRoadName(using: location)
    recalcFare()
  }

  private func isFreshLocation(_ location: CLLocation) -> Bool {
    if let tripStart = stateMachine.startTime {
      guard location.timestamp >= tripStart.addingTimeInterval(-2) else { return false }
    }

    return true
  }

  private func isPlausibleDistanceJump(
    delta: CLLocationDistance,
    from previous: CLLocation,
    to current: CLLocation,
    observedDelta: TimeInterval?
  ) -> Bool {
    let timestampDelta = current.timestamp.timeIntervalSince(previous.timestamp)
    guard timestampDelta > 0 else {
      Log.location.debug("Ignoring location update with non-increasing timestamp; dt=\(timestampDelta, format: .fixed(precision: 3))s")
      return false
    }

    let effectiveDelta = effectiveTimeDelta(
      delta: delta,
      timestampDelta: timestampDelta,
      observedDelta: observedDelta
    )

    let impliedSpeedKph = (delta / effectiveDelta) * 3.6
    guard impliedSpeedKph <= LocationValidation.maxAcceptedImpliedSpeedKph else {
      Log.location.warning(
        "Ignoring implausible jump; delta=\(delta, format: .fixed(precision: 2))m dt=\(effectiveDelta, format: .fixed(precision: 2))s tsDelta=\(timestampDelta, format: .fixed(precision: 2))s speed=\(impliedSpeedKph, format: .fixed(precision: 2))km/h"
      )
      return false
    }

    return true
  }

  private func effectiveTimeDelta(
    delta: CLLocationDistance,
    timestampDelta: TimeInterval,
    observedDelta: TimeInterval?
  ) -> TimeInterval {
    // GPX/simulator feeds can provide timestamps that are far apart while callbacks arrive quickly.
    // Apply observed-cadence validation only for very large jumps to avoid over-rejecting normal updates.
    if delta >= LocationValidation.observedCadenceValidationThresholdMeters,
      let observedDelta,
      observedDelta > 0
    {
      return min(timestampDelta, max(observedDelta, 1))
    }
    return timestampDelta
  }

  private func refreshCurrentRoadName(using location: CLLocation) {
    guard shouldLookupRoadName(using: location) else { return }
    lastRoadGeocodeAt = Date()
    lastRoadGeocodeLocation = location
    roadGeocoder.cancelGeocode()
    roadGeocodeTask?.cancel()

    roadGeocodeTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let placemarks = try await self.reverseGeocodeLocation(location)
        guard !Task.isCancelled else { return }
        let road = Self.roadName(from: placemarks.first)
        self.currentRoadName = road ?? ""
      } catch {
        // Keep previous road name on geocoding failures.
      }
    }
  }

  @MainActor
  private func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark] {
    try await withCheckedThrowingContinuation { continuation in
      roadGeocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: placemarks ?? [])
      }
    }
  }

  private func shouldLookupRoadName(using location: CLLocation) -> Bool {
    let now = Date()
    let isPeriodicUpdateDue = lastRoadGeocodeAt.map { now.timeIntervalSince($0) >= 60 } ?? true
    let hasSignificantDirectionChange = headingChangeOverLast64Meters.map { $0 > 45 } ?? false
    guard isPeriodicUpdateDue || hasSignificantDirectionChange else { return false }

    let distanceSinceLastLookup = lastRoadGeocodeLocation.map { location.distance(from: $0) } ?? .greatestFiniteMagnitude
    guard distanceSinceLastLookup >= 32 else { return false }

    return currentSpeedKph >= 5 || !isWaiting
  }

  private var headingChangeOverLast64Meters: Double? {
    guard points.count >= 3 else { return nil }
    guard let currentHeading = heading(
      from: points[points.count - 2].coordinate,
      to: points[points.count - 1].coordinate
    ) else {
      return nil
    }

    var traversed: CLLocationDistance = 0
    var index = points.count - 1
    while index > 0 && traversed < 64 {
      let newer = CLLocation(latitude: points[index].latitude, longitude: points[index].longitude)
      let older = CLLocation(latitude: points[index - 1].latitude, longitude: points[index - 1].longitude)
      traversed += newer.distance(from: older)
      index -= 1
    }

    guard index > 0 else { return nil }
    guard let priorHeading = heading(
      from: points[index - 1].coordinate,
      to: points[index].coordinate
    ) else {
      return nil
    }

    let delta = abs(currentHeading - priorHeading).truncatingRemainder(dividingBy: 360)
    return delta > 180 ? 360 - delta : delta
  }

  private func heading(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double? {
    let startLat = start.latitude * .pi / 180
    let startLon = start.longitude * .pi / 180
    let endLat = end.latitude * .pi / 180
    let endLon = end.longitude * .pi / 180

    let deltaLon = endLon - startLon
    let y = sin(deltaLon) * cos(endLat)
    let x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(deltaLon)
    guard !(abs(x) < 0.000001 && abs(y) < 0.000001) else { return nil }

    let radians = atan2(y, x)
    let degrees = radians * 180 / .pi
    return (degrees + 360).truncatingRemainder(dividingBy: 360)
  }

  private static func roadName(from placemark: CLPlacemark?) -> String? {
    guard let placemark else { return nil }
    let primary = [placemark.subThoroughfare, placemark.thoroughfare]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")

    if !primary.isEmpty { return primary }

    let fallback = [placemark.name, placemark.locality]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty }

    return fallback
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
