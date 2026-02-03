import CoreLocation
import Foundation

struct TripPoint: Codable, Hashable, Identifiable, Sendable {
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

struct TripConditions: Equatable, Sendable {
  var isNight: Bool

  static let clear = TripConditions(isNight: false)

  func multiplier(using settings: MeterSettings) -> Double {
    isNight ? settings.nightMultiplier : 1
  }
}

extension TripConditions: Codable {
  enum CodingKeys: String, CodingKey {
    case isNight
    case isRaining // legacy, ignored on decode
    case isHeavyTraffic // legacy, ignored on decode
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    isNight = try container.decode(Bool.self, forKey: .isNight)
    // Discard legacy rain/traffic fields if present
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(isNight, forKey: .isNight)
  }
}

struct MeterSettings: Equatable, Sendable {
  var baseFare: Double
  var perKmRate: Double
  var perMinuteRate: Double // Legacy, kept for backward compatibility
  var includedKm: Double
  var minFare: Double
  var nightMultiplier: Double
  var nightStartHour: Int
  var nightEndHour: Int
  var freeWaitMinutes: Double
  var waitIntervalMinutes: Double
  var waitIntervalCharge: Double

  static let bengaluruDefault = MeterSettings(
    baseFare: 36,
    perKmRate: 18,
    perMinuteRate: 0,
    includedKm: 2.0,
    minFare: 36,
    nightMultiplier: 1.5,
    nightStartHour: 22,
    nightEndHour: 5,
    freeWaitMinutes: 5,
    waitIntervalMinutes: 15,
    waitIntervalCharge: 10
  )
}

extension MeterSettings: Codable {
  enum CodingKeys: String, CodingKey {
    case baseFare, perKmRate, perMinuteRate, includedKm, minFare, nightMultiplier
    case nightStartHour, nightEndHour
    case freeWaitMinutes, waitIntervalMinutes, waitIntervalCharge
    case rainMultiplier // legacy, ignored on decode
    case trafficMultiplier // legacy, ignored on decode
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseFare = try container.decode(Double.self, forKey: .baseFare)
    perKmRate = try container.decode(Double.self, forKey: .perKmRate)
    perMinuteRate = try container.decode(Double.self, forKey: .perMinuteRate)
    includedKm = try container.decodeIfPresent(Double.self, forKey: .includedKm)
      ?? MeterSettings.bengaluruDefault.includedKm
    minFare = try container.decode(Double.self, forKey: .minFare)
    nightMultiplier = try container.decode(Double.self, forKey: .nightMultiplier)
    nightStartHour = try container.decodeIfPresent(Int.self, forKey: .nightStartHour)
      ?? MeterSettings.bengaluruDefault.nightStartHour
    nightEndHour = try container.decodeIfPresent(Int.self, forKey: .nightEndHour)
      ?? MeterSettings.bengaluruDefault.nightEndHour
    // New fields with backward-compatible defaults for old persisted data
    freeWaitMinutes = try container.decodeIfPresent(Double.self, forKey: .freeWaitMinutes)
      ?? MeterSettings.bengaluruDefault.freeWaitMinutes
    waitIntervalMinutes = try container.decodeIfPresent(Double.self, forKey: .waitIntervalMinutes)
      ?? MeterSettings.bengaluruDefault.waitIntervalMinutes
    waitIntervalCharge = try container.decodeIfPresent(Double.self, forKey: .waitIntervalCharge)
      ?? MeterSettings.bengaluruDefault.waitIntervalCharge
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(baseFare, forKey: .baseFare)
    try container.encode(perKmRate, forKey: .perKmRate)
    try container.encode(perMinuteRate, forKey: .perMinuteRate)
    try container.encode(includedKm, forKey: .includedKm)
    try container.encode(minFare, forKey: .minFare)
    try container.encode(nightMultiplier, forKey: .nightMultiplier)
    try container.encode(nightStartHour, forKey: .nightStartHour)
    try container.encode(nightEndHour, forKey: .nightEndHour)
    try container.encode(freeWaitMinutes, forKey: .freeWaitMinutes)
    try container.encode(waitIntervalMinutes, forKey: .waitIntervalMinutes)
    try container.encode(waitIntervalCharge, forKey: .waitIntervalCharge)
  }
}

extension MeterSettings {
  func isNight(at date: Date) -> Bool {
    let hour = Calendar.autoupdatingCurrent.component(.hour, from: date)
    if nightStartHour == nightEndHour {
      return false
    }
    if nightStartHour < nightEndHour {
      return hour >= nightStartHour && hour < nightEndHour
    }
    return hour >= nightStartHour || hour < nightEndHour
  }
}

struct RateSnapshot: Equatable, Sendable {
  let baseFare: Double
  let perKmRate: Double
  let perMinuteRate: Double // Legacy, kept for backward compatibility
  let includedKm: Double
  let minFare: Double
  let nightMultiplier: Double
  let nightStartHour: Int
  let nightEndHour: Int
  let freeWaitMinutes: Double
  let waitIntervalMinutes: Double
  let waitIntervalCharge: Double

  init(settings: MeterSettings) {
    baseFare = settings.baseFare
    perKmRate = settings.perKmRate
    perMinuteRate = settings.perMinuteRate
    includedKm = settings.includedKm
    minFare = settings.minFare
    nightMultiplier = settings.nightMultiplier
    nightStartHour = settings.nightStartHour
    nightEndHour = settings.nightEndHour
    freeWaitMinutes = settings.freeWaitMinutes
    waitIntervalMinutes = settings.waitIntervalMinutes
    waitIntervalCharge = settings.waitIntervalCharge
  }
}

extension RateSnapshot: Codable {
  enum CodingKeys: String, CodingKey {
    case baseFare, perKmRate, perMinuteRate, includedKm, minFare, nightMultiplier
    case nightStartHour, nightEndHour
    case freeWaitMinutes, waitIntervalMinutes, waitIntervalCharge
    case rainMultiplier // legacy, ignored on decode
    case trafficMultiplier // legacy, ignored on decode
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseFare = try container.decode(Double.self, forKey: .baseFare)
    perKmRate = try container.decode(Double.self, forKey: .perKmRate)
    perMinuteRate = try container.decode(Double.self, forKey: .perMinuteRate)
    includedKm = try container.decodeIfPresent(Double.self, forKey: .includedKm)
      ?? MeterSettings.bengaluruDefault.includedKm
    minFare = try container.decode(Double.self, forKey: .minFare)
    nightMultiplier = try container.decode(Double.self, forKey: .nightMultiplier)
    nightStartHour = try container.decodeIfPresent(Int.self, forKey: .nightStartHour)
      ?? MeterSettings.bengaluruDefault.nightStartHour
    nightEndHour = try container.decodeIfPresent(Int.self, forKey: .nightEndHour)
      ?? MeterSettings.bengaluruDefault.nightEndHour
    // New fields with backward-compatible defaults for old persisted trips
    freeWaitMinutes = try container.decodeIfPresent(Double.self, forKey: .freeWaitMinutes)
      ?? MeterSettings.bengaluruDefault.freeWaitMinutes
    waitIntervalMinutes = try container.decodeIfPresent(Double.self, forKey: .waitIntervalMinutes)
      ?? MeterSettings.bengaluruDefault.waitIntervalMinutes
    waitIntervalCharge = try container.decodeIfPresent(Double.self, forKey: .waitIntervalCharge)
      ?? MeterSettings.bengaluruDefault.waitIntervalCharge
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(baseFare, forKey: .baseFare)
    try container.encode(perKmRate, forKey: .perKmRate)
    try container.encode(perMinuteRate, forKey: .perMinuteRate)
    try container.encode(includedKm, forKey: .includedKm)
    try container.encode(minFare, forKey: .minFare)
    try container.encode(nightMultiplier, forKey: .nightMultiplier)
    try container.encode(nightStartHour, forKey: .nightStartHour)
    try container.encode(nightEndHour, forKey: .nightEndHour)
    try container.encode(freeWaitMinutes, forKey: .freeWaitMinutes)
    try container.encode(waitIntervalMinutes, forKey: .waitIntervalMinutes)
    try container.encode(waitIntervalCharge, forKey: .waitIntervalCharge)
  }
}

struct Trip: Codable, Identifiable, Sendable {
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
