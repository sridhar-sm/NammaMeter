import Foundation

struct SurchargeCondition: Codable, Equatable, Sendable {
  var startHour: Int?
  var endHour: Int?
  var daysOfWeek: [Int]?

  var isAlways: Bool {
    startHour == nil && endHour == nil && daysOfWeek == nil
  }

  func matches(at date: Date) -> Bool {
    if isAlways { return true }
    let calendar = Calendar.autoupdatingCurrent
    let hour = calendar.component(.hour, from: date)
    let weekday = calendar.component(.weekday, from: date)

    let timeMatches: Bool
    if let start = startHour, let end = endHour {
      if start == end {
        timeMatches = true
      } else if start < end {
        timeMatches = hour >= start && hour < end
      } else {
        timeMatches = hour >= start || hour < end
      }
    } else {
      timeMatches = true
    }

    let dayMatches: Bool
    if let days = daysOfWeek {
      dayMatches = days.contains(weekday)
    } else {
      dayMatches = true
    }

    return timeMatches && dayMatches
  }

  static func timeOfDay(start: Int, end: Int) -> SurchargeCondition {
    SurchargeCondition(startHour: start, endHour: end, daysOfWeek: nil)
  }

  static func weekdays(start: Int, end: Int) -> SurchargeCondition {
    SurchargeCondition(startHour: start, endHour: end, daysOfWeek: [2, 3, 4, 5, 6])
  }

  static let always = SurchargeCondition(startHour: nil, endHour: nil, daysOfWeek: nil)
}

enum SurchargeType: Equatable, Sendable {
  case percentageOfFare(Double)
  case fixedAmount(Double)
}

extension SurchargeType: Codable {
  enum CodingKeys: String, CodingKey {
    case percentageOfFare
    case fixedAmount
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let value = try container.decodeIfPresent(Double.self, forKey: .percentageOfFare) {
      self = .percentageOfFare(value)
    } else if let value = try container.decodeIfPresent(Double.self, forKey: .fixedAmount) {
      self = .fixedAmount(value)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "SurchargeType must have percentageOfFare or fixedAmount"))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .percentageOfFare(let value):
      try container.encode(value, forKey: .percentageOfFare)
    case .fixedAmount(let value):
      try container.encode(value, forKey: .fixedAmount)
    }
  }
}

struct FareSurcharge: Codable, Identifiable, Equatable, Sendable {
  var id: String
  var name: String
  var type: SurchargeType
  var conditions: [SurchargeCondition]

  func isActive(at date: Date) -> Bool {
    if conditions.isEmpty { return true }
    return conditions.contains { $0.matches(at: date) }
  }
}
