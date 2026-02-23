import Foundation
import Observation

@MainActor
@Observable
final class WatchTripStore {

  // MARK: - Trip State

  private(set) var tripState: TripMeterState = .forHire
  private(set) var fare: Double = 0
  private(set) var currencyCode: String = "INR"
  private(set) var distanceMeters: Double = 0
  private(set) var elapsedSeconds: TimeInterval = 0
  private(set) var waitingSeconds: TimeInterval = 0
  private(set) var currentSpeedKph: Double = 0
  private(set) var isWaiting: Bool = false
  private(set) var isNight: Bool = false
  private(set) var cityName: String = ""
  private(set) var vehicleType: String = ""
  private(set) var currentRoadName: String = ""
  private(set) var whatIfResults: [WatchWhatIfResult] = []

  // MARK: - Config

  private(set) var config: WatchConfig?

  var meterFaceStyle: MeterFaceStyle {
    guard let raw = config?.meterFaceStyle else { return .superMeter }
    return MeterFaceStyle(rawValue: raw) ?? .superMeter
  }

  var digitWheelStyle: DigitWheelStyle {
    guard let raw = config?.digitWheelStyle else { return .disk }
    return DigitWheelStyle(rawValue: raw) ?? .disk
  }

  // MARK: - Completed Trips (last 5)

  private(set) var recentTrips: [WatchTripSummary] = []
  private let maxRecentTrips = 5

  // MARK: - Update timestamp for ordering

  private var lastUpdateTimestamp: Date = .distantPast

  // MARK: - Apply Updates

  func applyConfig(_ newConfig: WatchConfig) {
    config = newConfig
    cityName = newConfig.cityName
    vehicleType = newConfig.vehicleType
    currencyCode = newConfig.currencyCode
  }

  func applyTripUpdate(_ update: WatchTripUpdate) {
    // Discard stale messages
    guard update.timestamp > lastUpdateTimestamp else { return }
    lastUpdateTimestamp = update.timestamp

    tripState = TripMeterState(wireValue: update.state) ?? .forHire
    fare = update.fare
    currencyCode = update.currencyCode
    distanceMeters = update.distanceMeters
    elapsedSeconds = update.elapsedSeconds
    waitingSeconds = update.waitingSeconds
    currentSpeedKph = update.currentSpeedKph
    isWaiting = update.isWaiting
    isNight = update.isNight
    cityName = update.cityName
    vehicleType = update.vehicleType
    currentRoadName = update.currentRoadName
    whatIfResults = update.whatIfResults
  }

  func addCompletedTrip(_ summary: WatchTripSummary) {
    // Avoid duplicates
    guard !recentTrips.contains(where: { $0.id == summary.id }) else { return }
    recentTrips.insert(summary, at: 0)
    if recentTrips.count > maxRecentTrips {
      recentTrips.removeLast()
    }
  }

  // MARK: - Formatted Values

  var formattedFare: String {
    formatCurrency(fare, code: currencyCode)
  }

  /// Fare formatted with 1 decimal digit for the LCD (Neo Digital) display.
  var formattedFareLCD: String {
    fare.formatted(.currency(code: currencyCode).precision(.fractionLength(1)))
  }

  var formattedDistance: String {
    let km = distanceMeters / 1000
    if km < 0.1 { return "0.0 km" }
    return String(format: "%.1f km", km)
  }

  var formattedWaiting: String {
    formattedHHMM(waitingSeconds)
  }

  var formattedElapsedTime: String {
    formattedHHMM(elapsedSeconds)
  }

  private func formattedHHMM(_ interval: TimeInterval) -> String {
    let total = max(Int(interval), 0)
    let h = total / 3600
    let m = (total % 3600) / 60
    return String(format: "%d:%02d", h, m)
  }

  var averageSpeedKph: Double {
    guard elapsedSeconds > 0 else { return 0 }
    return (distanceMeters / elapsedSeconds) * 3.6
  }

  var formattedSpeed: String {
    String(format: "%.1f km/h", averageSpeedKph)
  }
}
