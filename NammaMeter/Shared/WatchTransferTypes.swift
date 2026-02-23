import Foundation

// MARK: - Watch Configuration (iPhone → Watch via applicationContext)

/// Synced from iPhone whenever city, vehicle, favorites, or meter style changes.
struct WatchConfig: Codable, Sendable {
  let cityName: String
  let vehicleType: String
  let vehicleDisplayName: String
  let currencyCode: String
  let meterFaceStyle: String
  let digitWheelStyle: String
  let whatIfFavorites: [WatchFavoriteSummary]
}

struct WatchFavoriteSummary: Codable, Sendable, Identifiable {
  let cityName: String
  let vehicleType: String
  let vehicleDisplayName: String
  let currencyCode: String

  var id: String { cityName + ":" + vehicleType }
}

// MARK: - Live Trip Update (iPhone → Watch via sendMessage)

/// Pushed from iPhone every ~1-2 seconds during an active trip.
struct WatchTripUpdate: Codable, Sendable {
  let timestamp: Date
  let state: String
  let fare: Double
  let currencyCode: String
  let distanceMeters: Double
  let elapsedSeconds: TimeInterval
  let waitingSeconds: TimeInterval
  let currentSpeedKph: Double
  let isWaiting: Bool
  let isNight: Bool
  let cityName: String
  let vehicleType: String
  let currentRoadName: String
  let whatIfResults: [WatchWhatIfResult]
}

struct WatchWhatIfResult: Codable, Sendable, Identifiable {
  let cityName: String
  let vehicleType: String
  let vehicleDisplayName: String
  let currencyCode: String
  let fare: Double

  var id: String { cityName + ":" + vehicleType }
}

// MARK: - Completed Trip Summary (iPhone → Watch via transferUserInfo)

/// Sent after a trip completes for guaranteed delivery.
struct WatchTripSummary: Codable, Sendable {
  let id: UUID
  let startDate: Date
  let endDate: Date
  let fare: Double
  let currencyCode: String
  let distanceMeters: Double
  let duration: TimeInterval
  let cityName: String
  let vehicleType: String
}

// MARK: - Watch Commands (Watch → iPhone via sendMessage)

/// Commands sent from Watch to control the meter on iPhone.
enum WatchCommand: String, Codable, Sendable {
  case startTrip
  case stopTrip
  case enterWait
  case exitWait
  case resetTrip
}

// MARK: - TripMeterState Wire Format

extension TripMeterState {
  var wireValue: String {
    switch self {
    case .forHire: "forHire"
    case .inProgress: "inProgress"
    case .complete: "complete"
    }
  }

  init?(wireValue: String) {
    switch wireValue {
    case "forHire": self = .forHire
    case "inProgress": self = .inProgress
    case "complete": self = .complete
    default: return nil
    }
  }
}

// MARK: - Message Keys

/// Keys used for WatchConnectivity message dictionaries.
enum WatchMessageKey {
  static let config = "config"
  static let tripUpdate = "tripUpdate"
  static let tripSummary = "tripSummary"
  static let command = "command"
  static let commandAck = "commandAck"
}
