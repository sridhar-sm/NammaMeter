import Foundation

enum BundledExchangeRates {
  static let table = ExchangeRateTable(
    baseCurrency: "EUR",
    rates: [
      "INR": 94.50,
      "USD": 1.08,
      "GBP": 0.86,
      "AED": 3.97,
      "SGD": 1.45,
      "THB": 37.50,
    ],
    fetchedAt: Date(timeIntervalSince1970: 1_739_404_800) // 2025-02-13
  )
}
