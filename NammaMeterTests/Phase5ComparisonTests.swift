import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class Phase5ComparisonTests: XCTestCase {

  // MARK: - WhatIfCalculator with trip data

  func testTripComparisonCalculatesCorrectResults() {
    let favorites = [
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi),
    ]

    let results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { fav in
        FareCatalog.entries.first {
          $0.profile.cityId == fav.cityId && $0.profile.vehicleType == fav.vehicleType
        }?.profile
      },
      distanceKm: 5.0,
      elapsedTime: 1800,
      waitingTime: 300,
      tripDate: Date(),
      isNight: false
    )

    XCTAssertEqual(results.count, 2)

    let delhi = results.first { $0.favorite.cityId == "delhi" }
    XCTAssertNotNil(delhi)
    XCTAssertEqual(delhi?.currencyCode, "INR")
    XCTAssertGreaterThan(delhi?.fareInNativeCurrency ?? 0, 0)

    let nyc = results.first { $0.favorite.cityId == "nyc" }
    XCTAssertNotNil(nyc)
    XCTAssertEqual(nyc?.currencyCode, "USD")
    XCTAssertGreaterThan(nyc?.fareInNativeCurrency ?? 0, 0)
  }

  func testTripComparisonEmptyWithNoFavorites() {
    let results = WhatIfCalculator.calculateAll(
      favorites: [],
      profileLookup: { _ in nil },
      distanceKm: 5.0,
      elapsedTime: 1800,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    XCTAssertTrue(results.isEmpty)
  }

  func testTripComparisonUsesCurrentRates() {
    // Verify that calculateAll uses the profile we provide (current rates)
    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)
    let profile = FareCatalog.entries.first {
      $0.profile.cityId == "delhi" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile

    let result = WhatIfCalculator.calculate(
      favorite: favorite,
      profile: profile,
      distanceKm: 5.0,
      elapsedTime: 1800,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    // Delhi auto: base=25, includedKm=2, perKm=8, so fare = 25 + (5-2)*8 = 49
    XCTAssertEqual(result.fareInNativeCurrency, 49)
    XCTAssertEqual(result.currencyCode, "INR")
    XCTAssertEqual(result.cityName, profile.name)
  }

  // MARK: - Currency code in trips

  func testTripWithCurrencyCodeInRateSnapshot() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(
      settings: settings,
      cityId: "nyc",
      cityName: "New York City",
      vehicleType: VehicleTypeCatalog.yellowTaxi,
      currencyCode: "USD"
    )

    XCTAssertEqual(snapshot.currencyCode, "USD")
    XCTAssertEqual(snapshot.vehicleType, VehicleTypeCatalog.yellowTaxi)
  }

  func testTripWithDefaultCurrencyCode() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")

    XCTAssertNil(snapshot.currencyCode)
    // In views, this would fallback to "INR" via ?? "INR"
  }

  // MARK: - formatCurrency global helper

  func testFormatCurrencyINRNoDecimals() {
    let formatted = formatCurrency(150, code: "INR")
    // INR formatting should have 0 decimal places
    XCTAssertFalse(formatted.contains("."), "INR should not have decimal places")
    XCTAssertTrue(formatted.contains("150") || formatted.contains("150"), "Should contain the amount")
  }

  func testFormatCurrencyUSDTwoDecimals() {
    let formatted = formatCurrency(10.50, code: "USD")
    // USD formatting should have 2 decimal places
    XCTAssertTrue(formatted.contains("10.50") || formatted.contains("10,50"), "Should contain the amount with 2 decimals")
  }

  // MARK: - Multiple cities comparison

  func testTripComparisonWithMixedCurrencies() {
    let favorites = [
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "chennai", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "seattle", vehicleType: VehicleTypeCatalog.taxi),
    ]

    let results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { fav in
        FareCatalog.entries.first {
          $0.profile.cityId == fav.cityId && $0.profile.vehicleType == fav.vehicleType
        }?.profile
      },
      distanceKm: 10.0,
      elapsedTime: 2400,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    XCTAssertEqual(results.count, 3)

    // Delhi and Chennai should be INR
    let inrResults = results.filter { $0.currencyCode == "INR" }
    XCTAssertEqual(inrResults.count, 2)

    // Seattle should be USD
    let usdResults = results.filter { $0.currencyCode == "USD" }
    XCTAssertEqual(usdResults.count, 1)
  }

  func testTripComparisonSkipsUnfoundProfiles() {
    let favorites = [
      WhatIfFavorite(cityId: "nonexistent", vehicleType: "unknown"),
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
    ]

    let results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { fav in
        FareCatalog.entries.first {
          $0.profile.cityId == fav.cityId && $0.profile.vehicleType == fav.vehicleType
        }?.profile
      },
      distanceKm: 5.0,
      elapsedTime: 1800,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    // Only Delhi should be found, nonexistent skipped
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.favorite.cityId, "delhi")
  }
}
