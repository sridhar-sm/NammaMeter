import Foundation

protocol ExchangeRateFetching: Sendable {
  func fetchLatestRates() async throws -> ExchangeRateTable
}

final class ECBExchangeRateService: ExchangeRateFetching {
  private static let ecbURL = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")!

  func fetchLatestRates() async throws -> ExchangeRateTable {
    let (data, _) = try await URLSession.shared.data(from: Self.ecbURL)
    let rates = try ECBXMLParser.parse(data: data)
    return ExchangeRateTable(baseCurrency: "EUR", rates: rates, fetchedAt: Date())
  }
}

enum ECBXMLParserError: Error {
  case parsingFailed(String)
  case noRatesFound
}

enum ECBXMLParser {
  static func parse(data: Data) throws -> [String: Double] {
    let delegate = ECBXMLParserDelegate()
    let parser = XMLParser(data: data)
    parser.delegate = delegate
    guard parser.parse() else {
      throw ECBXMLParserError.parsingFailed(parser.parserError?.localizedDescription ?? "Unknown error")
    }
    guard !delegate.rates.isEmpty else {
      throw ECBXMLParserError.noRatesFound
    }
    return delegate.rates
  }
}

private class ECBXMLParserDelegate: NSObject, XMLParserDelegate {
  var rates: [String: Double] = [:]

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName: String?,
    attributes: [String: String]
  ) {
    guard elementName == "Cube",
          let currency = attributes["currency"],
          let rateString = attributes["rate"],
          let rate = Double(rateString)
    else { return }
    rates[currency] = rate
  }
}
