import Foundation
import XCTest
@testable import NammaMeter

final class ExchangeRateProviderTests: XCTestCase {

  // MARK: - Mock fetcher

  private final class MockFetcher: ExchangeRateFetching, @unchecked Sendable {
    var result: Result<ExchangeRateTable, Error> = .success(
      ExchangeRateTable(
        baseCurrency: "EUR",
        rates: ["USD": 1.10, "INR": 95.0],
        fetchedAt: Date()
      )
    )
    var fetchCount = 0

    func fetchLatestRates() async throws -> ExchangeRateTable {
      fetchCount += 1
      return try result.get()
    }
  }

  private final class FailingFetcher: ExchangeRateFetching, @unchecked Sendable {
    func fetchLatestRates() async throws -> ExchangeRateTable {
      throw URLError(.notConnectedToInternet)
    }
  }

  // MARK: - Init with no cache uses bundled

  @MainActor
  func testInitWithNoCacheUsesBundled() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")
    let fetcher = MockFetcher()
    // Make bundled rates appear fresh so no fetch is triggered
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    // Before load completes, should have bundled rates
    XCTAssertEqual(provider.rateTable.baseCurrency, "EUR")
    XCTAssertNotNil(provider.rateTable.rates["INR"])
  }

  // MARK: - Init with cached file loads cached

  @MainActor
  func testInitWithCachedFileLoadsCached() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")

    // Write a cached file
    let cached = ExchangeRateTable(
      baseCurrency: "EUR",
      rates: ["USD": 1.20, "INR": 99.0],
      fetchedAt: Date() // fresh
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(cached)
    try data.write(to: url)

    let fetcher = MockFetcher()
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    // Wait for load
    try await Task.sleep(for: .milliseconds(200))

    XCTAssertEqual(provider.rateTable.rates["USD"]!, 1.20, accuracy: 0.01)
    XCTAssertEqual(provider.rateTable.rates["INR"]!, 99.0, accuracy: 0.01)
    // Cache is fresh, so no fetch should happen
    XCTAssertEqual(fetcher.fetchCount, 0)
  }

  // MARK: - Stale cache triggers refresh

  @MainActor
  func testStaleCacheTriggersRefresh() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")

    // Write a stale cached file (8 days old)
    let staleDate = Date().addingTimeInterval(-8 * 24 * 60 * 60)
    let cached = ExchangeRateTable(
      baseCurrency: "EUR",
      rates: ["USD": 1.05, "INR": 90.0],
      fetchedAt: staleDate
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(cached)
    try data.write(to: url)

    let fetcher = MockFetcher()
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    // Wait for load + refresh
    try await Task.sleep(for: .milliseconds(500))

    XCTAssertEqual(fetcher.fetchCount, 1)
    // Should now have the fresh rates from mock
    XCTAssertEqual(provider.rateTable.rates["USD"]!, 1.10, accuracy: 0.01)
  }

  // MARK: - Fetch failure keeps current rates

  @MainActor
  func testFetchFailureKeepsCurrentRates() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")
    let fetcher = FailingFetcher()
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    // Wait for load attempt
    try await Task.sleep(for: .milliseconds(500))

    // Should still have bundled rates
    XCTAssertEqual(provider.rateTable.baseCurrency, "EUR")
    XCTAssertNotNil(provider.rateTable.rates["INR"])
  }

  // MARK: - convert/rate delegate to rateTable

  @MainActor
  func testConvertDelegatesToRateTable() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")
    let fetcher = MockFetcher()
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    let converted = provider.convert(100, from: "EUR", to: "INR")
    XCTAssertNotNil(converted)

    let rate = provider.rate(from: "USD", to: "INR")
    XCTAssertNotNil(rate)
  }

  @MainActor
  func testConvertUnknownCurrencyReturnsNil() async throws {
    let url = try TestHelpers.makeTempURL(filename: "exchange-rates.json")
    let fetcher = MockFetcher()
    let provider = ExchangeRateProvider(fetcher: fetcher, fileURL: url)

    XCTAssertNil(provider.convert(100, from: "XYZ", to: "INR"))
    XCTAssertNil(provider.rate(from: "XYZ", to: "INR"))
  }
}
