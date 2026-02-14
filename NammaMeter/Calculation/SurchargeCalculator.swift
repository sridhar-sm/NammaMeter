import Foundation

enum SurchargeCalculator {
  static func evaluate(
    _ surcharges: [FareSurcharge],
    subtotal: Double,
    at date: Date
  ) -> [AppliedSurcharge] {
    surcharges.compactMap { surcharge in
      guard surcharge.isActive(at: date) else { return nil }
      let amount: Double
      switch surcharge.type {
      case .percentageOfFare(let pct):
        amount = subtotal * pct
      case .fixedAmount(let fixed):
        amount = fixed
      }
      return AppliedSurcharge(
        id: surcharge.id,
        name: surcharge.name,
        type: surcharge.type,
        amount: amount
      )
    }
  }
}
