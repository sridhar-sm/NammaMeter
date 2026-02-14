import Foundation

struct AppliedSurcharge: Equatable, Sendable {
  let id: String
  let name: String
  let type: SurchargeType
  let amount: Double
}

struct FareBreakdown: Equatable, Sendable {
  let baseFare: Double
  let distanceFare: Double
  let timeFare: Double
  let waitingFare: Double
  let subtotal: Double
  let surcharges: [AppliedSurcharge]
  let surchargeTotal: Double
  let total: Double
}

protocol FareCalculationStrategy: Sendable {
  func calculateFare(
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    currentSpeedKph: Double?,
    surcharges: [FareSurcharge]?,
    tripDate: Date,
    isNight: Bool
  ) -> FareBreakdown
}
