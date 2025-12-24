import CoreLocation
import Foundation

struct TripPoint: Codable, Hashable, Identifiable {
  let id: UUID
  let latitude: Double
  let longitude: Double
  let timestamp: Date
  let speedMetersPerSecond: Double
  let horizontalAccuracy: Double

  init(id: UUID = UUID(), latitude: Double, longitude: Double, timestamp: Date, speedMetersPerSecond: Double, horizontalAccuracy: Double) {
    self.id = id
    self.latitude = latitude
    self.longitude = longitude
    self.timestamp = timestamp
    self.speedMetersPerSecond = speedMetersPerSecond
    self.horizontalAccuracy = horizontalAccuracy
  }

  init(location: CLLocation) {
    self.init(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      timestamp: location.timestamp,
      speedMetersPerSecond: max(location.speed, 0),
      horizontalAccuracy: location.horizontalAccuracy
    )
  }

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

struct TripConditions: Codable, Equatable {
  var isRaining: Bool
  var isNight: Bool
  var isHeavyTraffic: Bool

  static let clear = TripConditions(isRaining: false, isNight: false, isHeavyTraffic: false)

  func multiplier(using settings: MeterSettings) -> Double {
    let rain = isRaining ? settings.rainMultiplier : 1
    let night = isNight ? settings.nightMultiplier : 1
    let traffic = isHeavyTraffic ? settings.trafficMultiplier : 1
    return rain * night * traffic
  }
}

struct MeterSettings: Codable, Equatable {
  var baseFare: Double
  var perKmRate: Double
  var perMinuteRate: Double
  var minFare: Double
  var rainMultiplier: Double
  var nightMultiplier: Double
  var trafficMultiplier: Double

  static let bengaluruDefault = MeterSettings(
    baseFare: 30,
    perKmRate: 15,
    perMinuteRate: 1.5,
    minFare: 30,
    rainMultiplier: 1.2,
    nightMultiplier: 1.25,
    trafficMultiplier: 1.15
  )
}

struct RateSnapshot: Codable, Equatable {
  let baseFare: Double
  let perKmRate: Double
  let perMinuteRate: Double
  let minFare: Double
  let rainMultiplier: Double
  let nightMultiplier: Double
  let trafficMultiplier: Double

  init(settings: MeterSettings) {
    baseFare = settings.baseFare
    perKmRate = settings.perKmRate
    perMinuteRate = settings.perMinuteRate
    minFare = settings.minFare
    rainMultiplier = settings.rainMultiplier
    nightMultiplier = settings.nightMultiplier
    trafficMultiplier = settings.trafficMultiplier
  }
}

struct Trip: Codable, Identifiable {
  let id: UUID
  let startDate: Date
  let endDate: Date
  let distanceMeters: Double
  let duration: TimeInterval
  let fare: Double
  let points: [TripPoint]
  let conditions: TripConditions
  let rateSnapshot: RateSnapshot
  let multiplier: Double
}
