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
  var name: String?
  var startLocationName: String?
  var waitingDuration: TimeInterval

  init(
    id: UUID,
    startDate: Date,
    endDate: Date,
    distanceMeters: Double,
    duration: TimeInterval,
    fare: Double,
    points: [TripPoint],
    conditions: TripConditions,
    rateSnapshot: RateSnapshot,
    multiplier: Double,
    name: String? = nil,
    startLocationName: String? = nil,
    waitingDuration: TimeInterval = 0
  ) {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.distanceMeters = distanceMeters
    self.duration = duration
    self.fare = fare
    self.points = points
    self.conditions = conditions
    self.rateSnapshot = rateSnapshot
    self.multiplier = multiplier
    self.name = name
    self.startLocationName = startLocationName
    self.waitingDuration = waitingDuration
  }

  enum CodingKeys: String, CodingKey {
    case id
    case startDate
    case endDate
    case distanceMeters
    case duration
    case fare
    case points
    case conditions
    case rateSnapshot
    case multiplier
    case name
    case startLocationName
    case waitingDuration
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    startDate = try container.decode(Date.self, forKey: .startDate)
    endDate = try container.decode(Date.self, forKey: .endDate)
    distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
    duration = try container.decode(TimeInterval.self, forKey: .duration)
    fare = try container.decode(Double.self, forKey: .fare)
    points = try container.decode([TripPoint].self, forKey: .points)
    conditions = try container.decode(TripConditions.self, forKey: .conditions)
    rateSnapshot = try container.decode(RateSnapshot.self, forKey: .rateSnapshot)
    multiplier = try container.decode(Double.self, forKey: .multiplier)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    startLocationName = try container.decodeIfPresent(String.self, forKey: .startLocationName)
    waitingDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .waitingDuration) ?? 0
  }
}
