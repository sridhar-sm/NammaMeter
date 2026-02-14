import Foundation
import XCTest
@testable import NammaMeter

final class WhatIfCalculatorTests: XCTestCase {

  // MARK: - Calculate for Indian city (day)

  func testCalculateIndianCityDay() {
    let profile = FareCatalog.defaultProfile // Bengaluru auto-rickshaw
    let favorite = WhatIfFavorite(cityId: profile.cityId, vehicleType: profile.vehicleType)

    let result = WhatIfCalculator.calculate(
      favorite: favorite,
      profile: profile,
      distanceKm: 5.0,
      elapsedTime: 600,
      waitingTime: 0,
      tripDate: makeDate(hour: 12),
      isNight: false
    )

    XCTAssertEqual(result.cityName, "Bengaluru")
    XCTAssertEqual(result.currencyCode, "INR")
    XCTAssertEqual(result.vehicleType, VehicleTypeCatalog.autoRickshaw)

    // baseFare 36 + (5-2)*18 = 36 + 54 = 90
    // Day, surcharges inactive → total = 90
    XCTAssertEqual(result.fareInNativeCurrency, 90.0, accuracy: 0.01)
    XCTAssertEqual(result.fareBreakdown.baseFare, 36.0, accuracy: 0.01)
    XCTAssertEqual(result.fareBreakdown.distanceFare, 54.0, accuracy: 0.01)
  }

  // MARK: - Calculate for Indian city (night with surcharges)

  func testCalculateIndianCityNight() {
    let profile = FareCatalog.defaultProfile // Bengaluru with night surcharge
    let favorite = WhatIfFavorite(cityId: profile.cityId, vehicleType: profile.vehicleType)

    let result = WhatIfCalculator.calculate(
      favorite: favorite,
      profile: profile,
      distanceKm: 5.0,
      elapsedTime: 600,
      waitingTime: 0,
      tripDate: makeDate(hour: 23),
      isNight: true
    )

    // baseFare 36 + (5-2)*18 = 90 subtotal
    // Night surcharge 50% = 45
    // Total = 90 + 45 = 135
    XCTAssertEqual(result.fareInNativeCurrency, 135.0, accuracy: 0.01)
    XCTAssertEqual(result.fareBreakdown.surchargeTotal, 45.0, accuracy: 0.01)
  }

  // MARK: - Calculate for speed-based city

  func testCalculateSpeedBasedCity() {
    let profile = makeNYCProfile()
    let favorite = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")

    let result = WhatIfCalculator.calculate(
      favorite: favorite,
      profile: profile,
      distanceKm: 10.0,
      elapsedTime: 1800,
      waitingTime: 0,
      tripDate: makeDate(hour: 14),
      isNight: false
    )

    XCTAssertEqual(result.currencyCode, "USD")
    // distance: 10 * 2.18 = 21.80
    // time: 30 * 0.70 = 21.00
    // max(21.80, 21.00) = 21.80
    // subtotal = 3.00 + 21.80 = 24.80
    // No active surcharges at 14:00 (night is 20-6, rush is 16-20)
    // MTA + improvement always active: 0.50 + 1.00 = 1.50
    // total = 24.80 + 1.50 = 26.30
    XCTAssertEqual(result.fareInNativeCurrency, 26.30, accuracy: 0.01)
  }

  // MARK: - calculateAll

  func testCalculateAllWithMixedCities() {
    let bengaluruProfile = FareCatalog.defaultProfile
    let nycProfile = makeNYCProfile()

    let favorites = [
      WhatIfFavorite(cityId: "bengaluru", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi"),
    ]

    let results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { fav in
        switch fav.cityId {
        case "bengaluru": return bengaluruProfile
        case "nyc": return nycProfile
        default: return nil
        }
      },
      distanceKm: 5.0,
      elapsedTime: 600,
      waitingTime: 0,
      tripDate: makeDate(hour: 12),
      isNight: false
    )

    XCTAssertEqual(results.count, 2)
    XCTAssertEqual(results[0].cityName, "Bengaluru")
    XCTAssertEqual(results[1].cityName, "New York City")
  }

  func testCalculateAllMissingProfileFiltered() {
    let favorites = [
      WhatIfFavorite(cityId: "nonexistent", vehicleType: "taxi"),
    ]

    let results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { _ in nil },
      distanceKm: 5.0,
      elapsedTime: 600,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    XCTAssertTrue(results.isEmpty)
  }

  func testCalculateAllEmptyFavorites() {
    let results = WhatIfCalculator.calculateAll(
      favorites: [],
      profileLookup: { _ in nil },
      distanceKm: 5.0,
      elapsedTime: 600,
      waitingTime: 0,
      tripDate: Date(),
      isNight: false
    )

    XCTAssertTrue(results.isEmpty)
  }

  // MARK: - Helpers

  private func makeDate(hour: Int) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 10
    components.hour = hour
    return Calendar.autoupdatingCurrent.date(from: components)!
  }

  private func makeNYCProfile() -> CityFareProfile {
    CityFareProfile(
      id: "nyc-20260101",
      cityId: "nyc",
      name: "New York City",
      vehicleType: "yellow-taxi",
      cityKey: CityKey(city: "New York City", region: "New York", countryCode: "US", currencyCode: "USD"),
      rates: FareRates(
        baseFare: 3.00,
        perKmRate: 2.18,
        perMinuteRate: 0,
        includedKm: 0,
        minFare: 3.00,
        perMinuteWhenSlow: 0.70,
        slowSpeedThresholdKph: 19.0
      ),
      multipliers: FareMultipliers(night: 1.0),
      nightWindow: NightFareWindow(startHour: 0, endHour: 0),
      waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
      surcharges: [
        FareSurcharge(
          id: "nyc-night", name: "Night",
          type: .fixedAmount(1.00),
          conditions: [.timeOfDay(start: 20, end: 6)]
        ),
        FareSurcharge(
          id: "nyc-rush", name: "Rush Hour",
          type: .fixedAmount(2.50),
          conditions: [SurchargeCondition(startHour: 16, endHour: 20, daysOfWeek: [2, 3, 4, 5, 6])]
        ),
        FareSurcharge(
          id: "nyc-mta", name: "MTA Tax",
          type: .fixedAmount(0.50),
          conditions: [.always]
        ),
        FareSurcharge(
          id: "nyc-improvement", name: "Improvement",
          type: .fixedAmount(1.00),
          conditions: [.always]
        ),
      ],
      effectiveFrom: FareCatalog.startOfDay(year: 2026, month: 1, day: 1)
    )
  }
}
