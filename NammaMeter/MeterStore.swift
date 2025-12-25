import Combine
import CoreLocation
import Foundation

final class MeterStore: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var isOnTrip = false
  @Published var distanceMeters: Double = 0
  @Published var elapsed: TimeInterval = 0
  @Published var fare: Double = 0
  @Published var points: [TripPoint] = []
  @Published var currentSpeedKph: Double = 0
  @Published var isWaiting = false
  @Published var waitingDuration: TimeInterval = 0
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  @Published var locationError: String?
  @Published var conditions: TripConditions = .clear {
    didSet {
      guard let currentSettings else { return }
      multiplier = conditions.multiplier(using: currentSettings)
      recalcFare()
    }
  }

  private let locationManager: CLLocationManager
  private var timer: Timer?
  private var startDate: Date?
  private var lastLocation: CLLocation?
  private var currentSettings: MeterSettings?
  private var rateSnapshot: RateSnapshot?
  private var multiplier: Double = 1
  private var waitingStartedAt: Date?
  private var waitingAccumulated: TimeInterval = 0

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
    locationManager.startUpdatingLocation()
    updateBackgroundLocationState()
    startTimer()
  }

  func stopTrip(tripStore: TripStore) {
    guard isOnTrip else { return }
    isOnTrip = false
    stopWaiting()
    locationManager.stopUpdatingLocation()
    updateBackgroundLocationState()
    stopTimer()

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
    tripStore.resolveStartLocation(for: trip)
    currentSettings = nil
  }

  private func startTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.tick()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
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

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard isOnTrip else { return }
    let filtered = locations.filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 40 }
    guard !filtered.isEmpty else { return }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      for location in filtered {
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
      }
      recalcFare()
    }
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
