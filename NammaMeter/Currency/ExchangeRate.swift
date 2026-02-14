import Foundation

struct ExchangeRateTable: Codable, Equatable, Sendable {
  let baseCurrency: String
  let rates: [String: Double]
  let fetchedAt: Date

  func rate(from: String, to: String) -> Double? {
    let fromUpper = from.uppercased()
    let toUpper = to.uppercased()

    if fromUpper == toUpper { return 1.0 }

    let base = baseCurrency.uppercased()

    // from → base → to
    let fromRate: Double
    if fromUpper == base {
      fromRate = 1.0
    } else {
      guard let r = rates[fromUpper], r > 0 else { return nil }
      fromRate = r
    }

    let toRate: Double
    if toUpper == base {
      toRate = 1.0
    } else {
      guard let r = rates[toUpper] else { return nil }
      toRate = r
    }

    return toRate / fromRate
  }

  func convert(_ amount: Double, from: String, to: String) -> Double? {
    guard let r = rate(from: from, to: to) else { return nil }
    return amount * r
  }
}
