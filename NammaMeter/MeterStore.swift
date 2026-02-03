import CoreLocation
import Foundation
import Observation

enum TripMeterState {
  case forHire
  case inProgress
  case complete
}

@MainActor
@Observable
final class MeterStore: NSObject, @preconcurrency CLLocationManagerDelegate {
  var isOnTrip = false
  var distanceMeters: Double = 0
  var elapsed: TimeInterval = 0
  var fare: Double = 0
  var points: [TripPoint] = []
  var currentSpeedKph: Double = 0
  var isWaiting = false
  var waitingDuration: TimeInterval = 0
  var tripState: TripMeterState = .forHire
  var authorizationStatus: CLAuthorizationStatus = .notDetermined
  var locationError: String?
  var conditions: TripConditions = .clear {
    didSet {
      guard let currentSettings else { return }
      multiplier = conditions.multiplier(using: currentSettings)
      recalcFare()
    }
  }

  @ObservationIgnored private let locationManager: CLLocationManager
  @ObservationIgnored private var tickTask: Task<Void, Never>?
  @ObservationIgnored private var isUpdatingLocation = false
  @ObservationIgnored private let clock = ContinuousClock()
  @ObservationIgnored private var startDate: Date?
  @ObservationIgnored private var lastLocation: CLLocation?
  @ObservationIgnored private var currentSettings: MeterSettings?
  @ObservationIgnored private var rateSnapshot: RateSnapshot?
  @ObservationIgnored private var multiplier: Double = 1
  @ObservationIgnored private var waitingStartedAt: Date?
  @ObservationIgnored private var waitingAccumulated: TimeInterval = 0

  override init() {
    locationManager = CLLocationManager()
    super.init()
    locationManager.delegate = self
    locationManager.activityType = .automotiveNavigation
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 8
    locationManager.pausesLocationUpdatesAutomatically = false
    authorizationStatus = locationManager.authorizationStatus
  }

  func requestAuthorization() {
    if authorizationStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }
  }

  func requestAlwaysAuthorization() {
    guard authorizationStatus == .authorizedWhenInUse else { return }
    locationManager.requestAlwaysAuthorization()
  }

  func startTrip(settings: MeterSettings, cityId: String? = nil, cityName: String? = nil) {
    guard !isOnTrip else { return }
    currentSettings = settings
    rateSnapshot = RateSnapshot(settings: settings, cityId: cityId, cityName: cityName)
    refreshTimeBasedConditions(reference: Date())
    multiplier = conditions.multiplier(using: settings)
    isOnTrip = true
    points = []
    distanceMeters = 0
    elapsed = 0
    fare = settings.minFare
    currentSpeedKph = 0
    isWaiting = false
    waitingDuration = 0
    waitingAccumulated = 0
    waitingStartedAt = nil
    tripState = .inProgress
    startDate = Date()
    lastLocation = nil
    locationError = nil

    authorizationStatus = locationManager.authorizationStatus
    requestAuthorization()
    if isAuthorizedForLocationUpdates {
      startLocationUpdates()
    }
    updateBackgroundLocationState()
    startTicking()
  }

  func stopTrip(tripStore: TripStore) {
    guard isOnTrip else { return }
    isOnTrip = false
    stopWaiting()
    stopLocationUpdates()
    updateBackgroundLocationState()
    stopTicking()

    let endDate = Date()
    let snapshot = rateSnapshot ?? RateSnapshot(settings: currentSettings ?? .bengaluruDefault)
    let trip = Trip(
      id: UUID(),
      startDate: startDate ?? endDate,
      endDate: endDate,
      distanceMeters: distanceMeters,
      duration: elapsed,
      fare: fare,
      points: points,
      conditions: conditions,
      rateSnapshot: snapshot,
      multiplier: multiplier,
      waitingDuration: waitingDuration
    )
    tripStore.add(trip)
    Task { await tripStore.resolveStartLocation(for: trip) }
    currentSettings = nil
    tripState = .complete
  }

  func resetToForHire() {
    guard tripState == .complete else { return }
    tripState = .forHire
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
    if let startDate {
      elapsed = now.timeIntervalSince(startDate)
    }
    recalcFare()
  }

  private func recalcFare() {
    guard let settings = currentSettings else { return }
    let distanceKm = distanceMeters / 1000
    let includedKm = settings.includedKm
    let chargeableDistanceKm = max(0, distanceKm - includedKm)
    let waitingCharge = calculateWaitingCharge(
      waitingDuration: waitingDuration,
      freeWaitMinutes: settings.freeWaitMinutes,
      waitIntervalMinutes: settings.waitIntervalMinutes,
      waitIntervalCharge: settings.waitIntervalCharge
    )
    let rawFare = settings.baseFare + (chargeableDistanceKm * settings.perKmRate) + waitingCharge
    let adjusted = rawFare * multiplier
    fare = max(settings.minFare, adjusted)
  }

  private func calculateWaitingCharge(
    waitingDuration: TimeInterval,
    freeWaitMinutes: Double,
    waitIntervalMinutes: Double,
    waitIntervalCharge: Double
  ) -> Double {
    let waitingMinutes = waitingDuration / 60
    let chargeableMinutes = max(0, waitingMinutes - freeWaitMinutes)
    guard waitIntervalMinutes > 0 else { return 0 }
    let intervals = ceil(chargeableMinutes / waitIntervalMinutes)
    return intervals * waitIntervalCharge
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
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

    currentSpeedKph = max(location.speed, 0) * 3.6
    let point = TripPoint(location: location)
    points.append(point)

    if let lastLocation {
      let delta = location.distance(from: lastLocation)
      if isWaiting && (location.speed >= 1.0 || delta > 8) {
        stopWaiting()
      }
      if delta > 2 {
        distanceMeters += delta
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
    waitingDuration = waitingAccumulated
  }

  private func updateWaitingDuration(_ now: Date) {
    if isWaiting, let waitingStartedAt {
      waitingDuration = waitingAccumulated + now.timeIntervalSince(waitingStartedAt)
    } else {
      waitingDuration = waitingAccumulated
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
}
