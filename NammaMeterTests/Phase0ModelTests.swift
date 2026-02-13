import Foundation
import XCTest
@testable import NammaMeter

final class Phase0ModelTests: XCTestCase {

  // MARK: - CityKey backward compatibility

  func testCityKeyDecodesWithoutCurrencyCode() throws {
    let json = """
    { "city": "Bengaluru", "region": "Karnataka", "countryCode": "IN" }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let key = try JSONDecoder().decode(CityKey.self, from: data)
    XCTAssertEqual(key.currencyCode, "INR")
    XCTAssertEqual(key.city, "Bengaluru")
  }

  func testCityKeyDecodesWithCurrencyCode() throws {
    let json = """
    { "city": "NYC", "region": "New York", "countryCode": "US", "currencyCode": "USD" }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let key = try JSONDecoder().decode(CityKey.self, from: data)
    XCTAssertEqual(key.currencyCode, "USD")
  }

  func testCityKeyRoundTrip() throws {
    let key = CityKey(city: "Seattle", region: "Washington", countryCode: "US", currencyCode: "USD")
    let data = try JSONEncoder().encode(key)
    let decoded = try JSONDecoder().decode(CityKey.self, from: data)
    XCTAssertEqual(key, decoded)
  }

  // MARK: - FareRates backward compatibility

  func testFareRatesDecodesWithoutSpeedFields() throws {
    let json = """
    { "baseFare": 36, "perKmRate": 18, "perMinuteRate": 0, "includedKm": 2.0, "minFare": 36 }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let rates = try JSONDecoder().decode(FareRates.self, from: data)
    XCTAssertNil(rates.perMinuteWhenSlow)
    XCTAssertNil(rates.slowSpeedThresholdKph)
    XCTAssertEqual(rates.baseFare, 36)
  }

  func testFareRatesDecodesWithSpeedFields() throws {
    let json = """
    {
      "baseFare": 3.00, "perKmRate": 2.18, "perMinuteRate": 0,
      "includedKm": 0, "minFare": 3.00,
      "perMinuteWhenSlow": 0.70, "slowSpeedThresholdKph": 19.3
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let rates = try JSONDecoder().decode(FareRates.self, from: data)
    XCTAssertEqual(rates.perMinuteWhenSlow, 0.70)
    XCTAssertEqual(rates.slowSpeedThresholdKph, 19.3)
  }

  func testFareRatesRoundTrip() throws {
    let rates = FareRates(
      baseFare: 3.25, perKmRate: 1.40, perMinuteRate: 0,
      includedKm: 0, minFare: 3.25,
      perMinuteWhenSlow: 0.42, slowSpeedThresholdKph: 18.0
    )
    let data = try JSONEncoder().encode(rates)
    let decoded = try JSONDecoder().decode(FareRates.self, from: data)
    XCTAssertEqual(rates, decoded)
  }

  // MARK: - CityFareProfile backward compatibility

  func testProfileDecodesWithoutNewFields() throws {
    let json = """
    {
      "id": "test-1",
      "cityId": "test-city",
      "name": "Test",
      "cityKey": { "city": "Test", "countryCode": "IN" },
      "rates": { "baseFare": 30, "perKmRate": 15, "perMinuteRate": 0, "includedKm": 2.0, "minFare": 30 },
      "multipliers": { "night": 1.5 },
      "waitCharges": { "freeWaitMinutes": 5, "waitIntervalMinutes": 15, "waitIntervalCharge": 5 },
      "effectiveFrom": "2026-01-01T00:00:00Z"
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let profile = try decoder.decode(CityFareProfile.self, from: data)

    XCTAssertEqual(profile.vehicleType, VehicleTypeCatalog.autoRickshaw)
    XCTAssertEqual(profile.cityKey.currencyCode, "INR")
    XCTAssertNil(profile.surcharges)
    XCTAssertNil(profile.flatRates)
    XCTAssertNil(profile.rates.perMinuteWhenSlow)
    XCTAssertNil(profile.rates.slowSpeedThresholdKph)
    XCTAssertEqual(profile.nightWindow.startHour, 22) // default
    XCTAssertEqual(profile.nightWindow.endHour, 5) // default
  }

  func testProfileDecodesWithAllNewFields() throws {
    let json = """
    {
      "id": "nyc-1",
      "cityId": "nyc",
      "name": "NYC",
      "vehicleType": "yellow-taxi",
      "cityKey": { "city": "NYC", "region": "New York", "countryCode": "US", "currencyCode": "USD" },
      "rates": {
        "baseFare": 3.00, "perKmRate": 2.18, "perMinuteRate": 0,
        "includedKm": 0, "minFare": 3.00,
        "perMinuteWhenSlow": 0.70, "slowSpeedThresholdKph": 19.3
      },
      "multipliers": { "night": 1.0 },
      "nightWindow": { "startHour": 0, "endHour": 0 },
      "waitCharges": { "freeWaitMinutes": 0, "waitIntervalMinutes": 0, "waitIntervalCharge": 0 },
      "surcharges": [
        {
          "id": "nyc-night",
          "name": "Night",
          "type": { "fixedAmount": 1.00 },
          "conditions": [{ "startHour": 20, "endHour": 6 }]
        }
      ],
      "effectiveFrom": "2026-01-01T00:00:00Z"
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let profile = try decoder.decode(CityFareProfile.self, from: data)

    XCTAssertEqual(profile.vehicleType, "yellow-taxi")
    XCTAssertEqual(profile.cityKey.currencyCode, "USD")
    XCTAssertEqual(profile.rates.perMinuteWhenSlow, 0.70)
    XCTAssertEqual(profile.rates.slowSpeedThresholdKph, 19.3)
    XCTAssertEqual(profile.surcharges?.count, 1)
    XCTAssertEqual(profile.surcharges?.first?.name, "Night")
  }

  func testProfileRoundTrip() throws {
    let profile = CityFareProfile(
      id: "test-rt",
      cityId: "test",
      name: "Test",
      vehicleType: VehicleTypeCatalog.taxi,
      cityKey: CityKey(city: "Test", region: nil, countryCode: "US", currencyCode: "USD"),
      rates: FareRates(baseFare: 3.25, perKmRate: 1.40, perMinuteRate: 0, includedKm: 0, minFare: 3.25,
                       perMinuteWhenSlow: 0.42, slowSpeedThresholdKph: 18.0),
      multipliers: FareMultipliers(night: 1.0),
      nightWindow: NightFareWindow(startHour: 0, endHour: 0),
      waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
      surcharges: [
        FareSurcharge(id: "night", name: "Night", type: .fixedAmount(1.00),
                      conditions: [.timeOfDay(start: 20, end: 6)])
      ],
      effectiveFrom: Date(timeIntervalSince1970: 1704067200)
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(profile)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(CityFareProfile.self, from: data)

    XCTAssertEqual(profile, decoded)
  }

  // MARK: - RateSnapshot backward compatibility

  func testRateSnapshotDecodesWithoutNewFields() throws {
    let json = """
    {
      "baseFare": 36, "perKmRate": 18, "perMinuteRate": 0,
      "includedKm": 2.0, "minFare": 36, "nightMultiplier": 1.5,
      "nightStartHour": 22, "nightEndHour": 5,
      "freeWaitMinutes": 5, "waitIntervalMinutes": 15, "waitIntervalCharge": 10
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(RateSnapshot.self, from: data)

    XCTAssertNil(snapshot.vehicleType)
    XCTAssertNil(snapshot.currencyCode)
    XCTAssertNil(snapshot.surcharges)
    XCTAssertEqual(snapshot.baseFare, 36)
  }

  func testRateSnapshotDecodesWithNewFields() throws {
    let json = """
    {
      "cityId": "nyc", "cityName": "NYC",
      "vehicleType": "yellow-taxi", "currencyCode": "USD",
      "baseFare": 3.00, "perKmRate": 2.18, "perMinuteRate": 0,
      "includedKm": 0, "minFare": 3.00, "nightMultiplier": 1.0,
      "nightStartHour": 0, "nightEndHour": 0,
      "freeWaitMinutes": 0, "waitIntervalMinutes": 0, "waitIntervalCharge": 0,
      "surcharges": [
        {
          "id": "mta",
          "name": "MTA Tax",
          "type": { "fixedAmount": 0.50 },
          "conditions": []
        }
      ]
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(RateSnapshot.self, from: data)

    XCTAssertEqual(snapshot.vehicleType, "yellow-taxi")
    XCTAssertEqual(snapshot.currencyCode, "USD")
    XCTAssertEqual(snapshot.surcharges?.count, 1)
    XCTAssertEqual(snapshot.surcharges?.first?.name, "MTA Tax")
  }

  func testRateSnapshotInitFromSettings() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      vehicleType: VehicleTypeCatalog.autoRickshaw,
      currencyCode: "INR",
      surcharges: [
        FareSurcharge(id: "night", name: "Night", type: .percentageOfFare(0.50),
                      conditions: [.timeOfDay(start: 22, end: 5)])
      ]
    )

    XCTAssertEqual(snapshot.vehicleType, VehicleTypeCatalog.autoRickshaw)
    XCTAssertEqual(snapshot.currencyCode, "INR")
    XCTAssertEqual(snapshot.surcharges?.count, 1)
    XCTAssertEqual(snapshot.baseFare, 36)
  }

  // MARK: - VehicleTypeCatalog

  func testVehicleTypeDisplayName() {
    XCTAssertEqual(VehicleTypeCatalog.displayName(for: "auto-rickshaw"), "Auto Rickshaw")
    XCTAssertEqual(VehicleTypeCatalog.displayName(for: "yellow-taxi"), "Yellow Taxi")
    XCTAssertEqual(VehicleTypeCatalog.displayName(for: "taxi-ac"), "Taxi (AC)")
  }

  func testVehicleTypeDisplayNameFallback() {
    XCTAssertEqual(VehicleTypeCatalog.displayName(for: "unknown-type"), "Unknown-Type")
  }

  func testVehicleTypeSymbol() {
    XCTAssertEqual(VehicleTypeCatalog.symbol(for: "auto-rickshaw"), "car.side")
    XCTAssertEqual(VehicleTypeCatalog.symbol(for: "taxi"), "car")
    XCTAssertEqual(VehicleTypeCatalog.symbol(for: "unknown"), "car")
  }

  // MARK: - FlatRateFare

  func testFlatRateFareCodable() throws {
    let fare = FlatRateFare(id: "jfk-manhattan", routeName: "JFK to Manhattan", fare: 70.0, currencyCode: "USD")
    let data = try JSONEncoder().encode(fare)
    let decoded = try JSONDecoder().decode(FlatRateFare.self, from: data)
    XCTAssertEqual(fare, decoded)
  }

  // MARK: - Catalog entries have new fields

  func testCatalogEntriesHaveCurrencyCode() {
    for entry in FareCatalog.entries {
      XCTAssertEqual(entry.profile.cityKey.currencyCode, "INR",
                     "\(entry.profile.name) should have INR currency")
    }
  }

  func testCatalogEntriesHaveVehicleType() {
    for entry in FareCatalog.entries {
      XCTAssertEqual(entry.profile.vehicleType, VehicleTypeCatalog.autoRickshaw,
                     "\(entry.profile.name) should have auto-rickshaw vehicle type")
    }
  }

  func testCatalogEntriesHaveSurcharges() {
    for entry in FareCatalog.entries {
      XCTAssertNotNil(entry.profile.surcharges,
                      "\(entry.profile.name) should have surcharges array")
      let nightSurcharges = entry.profile.surcharges?.filter { $0.name == "Night" } ?? []
      XCTAssertEqual(nightSurcharges.count, 1,
                     "\(entry.profile.name) should have exactly one Night surcharge")
    }
  }
}
