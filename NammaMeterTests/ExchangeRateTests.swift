import Foundation
import XCTest
@testable import NammaMeter

final class ExchangeRateTests: XCTestCase {

  private let table = ExchangeRateTable(
    baseCurrency: "EUR",
    rates: [
      "USD": 1.08,
      "INR": 94.50,
      "GBP": 0.86,
    ],
    fetchedAt: Date()
  )

  // MARK: - rate(from:to:)

  func testSameCurrencyReturns1() {
    XCTAssertEqual(table.rate(from: "INR", to: "INR"), 1.0)
    XCTAssertEqual(table.rate(from: "EUR", to: "EUR"), 1.0)
  }

  func testEURToOther() {
    let rate = table.rate(from: "EUR", to: "USD")
    XCTAssertEqual(rate!, 1.08, accuracy: 0.001)
  }

  func testOtherToEUR() {
    let rate = table.rate(from: "USD", to: "EUR")
    // 1/1.08
    XCTAssertEqual(rate!, 1.0 / 1.08, accuracy: 0.001)
  }

  func testCrossRate() {
    // USD→INR via EUR: INR/USD = 94.50/1.08
    let rate = table.rate(from: "USD", to: "INR")
    XCTAssertNotNil(rate)
    XCTAssertEqual(rate!, 94.50 / 1.08, accuracy: 0.01)
  }

  func testUnknownCurrencyReturnsNil() {
    XCTAssertNil(table.rate(from: "UNKNOWN", to: "INR"))
    XCTAssertNil(table.rate(from: "USD", to: "UNKNOWN"))
  }

  func testCaseInsensitive() {
    let rate = table.rate(from: "usd", to: "inr")
    XCTAssertNotNil(rate)
    XCTAssertEqual(rate!, 94.50 / 1.08, accuracy: 0.01)
  }

  // MARK: - convert

  func testConvertAmount() {
    let result = table.convert(100, from: "USD", to: "INR")
    XCTAssertNotNil(result)
    let expectedRate = 94.50 / 1.08
    XCTAssertEqual(result!, 100 * expectedRate, accuracy: 0.01)
  }

  func testConvertZero() {
    let result = table.convert(0, from: "USD", to: "INR")
    XCTAssertEqual(result!, 0, accuracy: 0.001)
  }

  func testConvertUnknownReturnsNil() {
    XCTAssertNil(table.convert(100, from: "XYZ", to: "INR"))
  }

  func testConvertSameCurrency() {
    let result = table.convert(42.5, from: "INR", to: "INR")
    XCTAssertEqual(result!, 42.5, accuracy: 0.001)
  }

  // MARK: - Bundled rates

  func testBundledTableHasRequiredCurrencies() {
    let bundled = BundledExchangeRates.table
    XCTAssertEqual(bundled.baseCurrency, "EUR")

    let required = ["INR", "USD", "GBP", "AED", "SGD", "THB"]
    for currency in required {
      XCTAssertNotNil(bundled.rates[currency], "Missing bundled rate for \(currency)")
    }
  }

  func testBundledTableCrossRateWorks() {
    let bundled = BundledExchangeRates.table
    let rate = bundled.rate(from: "USD", to: "INR")
    XCTAssertNotNil(rate)
    XCTAssertGreaterThan(rate!, 50) // USD→INR should be > 50
  }

  // MARK: - Codable

  func testExchangeRateTableRoundTrip() throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(table)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(ExchangeRateTable.self, from: data)

    XCTAssertEqual(decoded.baseCurrency, table.baseCurrency)
    XCTAssertEqual(decoded.rates, table.rates)
  }
}
