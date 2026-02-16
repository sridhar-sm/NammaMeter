import Foundation

enum FareRuleKind: String, CaseIterable, Sendable {
  case baseFare
  case distanceCharge
  case timeCharge
  case waitingCharge
  case speedBasedCharge
  case minimumFare
  case surcharge
}

struct FareRule: Identifiable, Equatable, Sendable {
  let id: String
  let kind: FareRuleKind
  let label: String
  let description: String
}

struct EvaluatedFareRule: Identifiable, Equatable, Sendable {
  let rule: FareRule
  let isActive: Bool
  let amount: Double

  var id: String { rule.id }
}

struct FareRuleContext: Equatable, Sendable {
  let tripState: TripMeterState
  let distanceKm: Double
  let elapsedTime: TimeInterval
  let waitingTime: TimeInterval
  let currentSpeedKph: Double?
  let tripDate: Date
  let currentFare: Double
}
