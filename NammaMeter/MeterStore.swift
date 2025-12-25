import CoreLocation
import Foundation
import Observation

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
  @ObservationIgnored private var locationUpdatesTask: Task<Void, Never>?
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
    locationManager.requestWhenInUseAuthorization()
  }

  func startTrip(settings: MeterSettings) {
    guard !isOnTrip else { return }
    currentSettings = settings
    rateSnapshot = RateSnapshot(settings: settings)
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
    startDate = Date()
    lastLocation = nil
    locationError = nil

    requestAuthorization()
    locationManager.requestAlwaysAuthorization()
    startLocationUpdates()
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
    locationUpdatesTask?.cancel()
    locationUpdatesTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        for try await update in CLLocationUpdate.liveUpdates() {
          if Task.isCancelled { break }
          guard let location = update.location else { continue }
          self.handleLocation(location)
        }
      } catch {
        locationError = error.localizedDescription
      }
    }
  }

  private func stopLocationUpdates() {
    locationUpdatesTask?.cancel()
    locationUpdatesTask = nil
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
    let includedKm = 2.0
    let chargeableDistanceKm = max(0, distanceKm - includedKm)
    let waitingMinutes = waitingDuration / 60
    let rawFare = settings.baseFare + (chargeableDistanceKm * settings.perKmRate) + (waitingMinutes * settings.perMinuteRate)
    let adjusted = rawFare * multiplier
    fare = max(settings.minFare, adjusted)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
    if isOnTrip {
      updateBackgroundLocationState()
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationError = error.localizedDescription
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
    let hour = Calendar.autoupdatingCurrent.component(.hour, from: reference)
    let nightNow = hour >= 22 || hour < 6
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
}
