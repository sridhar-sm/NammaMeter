import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ExchangeRateProvider {
  private(set) var rateTable: ExchangeRateTable

  @ObservationIgnored private let fetcher: ExchangeRateFetching
  @ObservationIgnored private let persistence: ExchangeRatePersistence
  @ObservationIgnored private static let stalenessThreshold: TimeInterval = 7 * 24 * 60 * 60 // 7 days

  init(fetcher: ExchangeRateFetching = ECBExchangeRateService(), fileURL: URL = ExchangeRateProvider.defaultURL) {
    self.fetcher = fetcher
    self.persistence = ExchangeRatePersistence(url: fileURL)
    self.rateTable = BundledExchangeRates.table
    Task { await load() }
  }

  func convert(_ amount: Double, from: String, to: String) -> Double? {
    rateTable.convert(amount, from: from, to: to)
  }

  func rate(from: String, to: String) -> Double? {
    rateTable.rate(from: from, to: to)
  }

  private func load() async {
    if let cached = await persistence.load() {
      rateTable = cached
      Log.persistence.info("Loaded cached exchange rates: \(cached.rates.count) currencies, fetched \(cached.fetchedAt)")
    }
    await refreshIfNeeded()
  }

  func refreshIfNeeded() async {
    let age = Date().timeIntervalSince(rateTable.fetchedAt)
    guard age > Self.stalenessThreshold else { return }

    do {
      let fresh = try await fetcher.fetchLatestRates()
      rateTable = fresh
      await persistence.save(fresh)
      Log.persistence.info("Refreshed exchange rates: \(fresh.rates.count) currencies")
    } catch {
      Log.persistence.error("Failed to refresh exchange rates: \(error.localizedDescription)")
    }
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("exchange-rates.json")
  }
}

private actor ExchangeRatePersistence {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func load() -> ExchangeRateTable? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(ExchangeRateTable.self, from: data)
  }

  func save(_ table: ExchangeRateTable) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(table) else { return }
    try? data.write(to: url, options: [.atomic])
  }
}
