import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class Phase4WhatIfTests: XCTestCase {

  private var mockLocationProvider: MockLocationProvider!
  private var meterStore: MeterStore!
  private var tripStore: TripStore!

  override func setUp() async throws {
    mockLocationProvider = MockLocationProvider()
    meterStore = MeterStore(locationProvider: mockLocationProvider)
    let tempURL = try TestHelpers.makeTempURL(filename: "trips_phase4.json")
    tripStore = TripStore(fileURL: tempURL)
    await TestHelpers.waitForTripStoreLoad(tripStore)
  }

  // MARK: - WhatIf profile capture

  func testStartTripCapturesWhatIfProfiles() {
    let settings = MeterSettings.bengaluruDefault
    let delhiProfile = FareCatalog.entries.first {
      $0.profile.cityId == "delhi" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile
    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      whatIfFavorites: [favorite],
      whatIfProfileLookup: { _ in delhiProfile }
    )

    // After startTrip, recalcFare is called which triggers recalcWhatIf
    XCTAssertEqual(meterStore.whatIfResults.count, 1)
    XCTAssertEqual(meterStore.whatIfResults.first?.cityName, "Delhi")
    XCTAssertEqual(meterStore.whatIfResults.first?.vehicleType, VehicleTypeCatalog.autoRickshaw)
    XCTAssertEqual(meterStore.whatIfResults.first?.currencyCode, "INR")
  }

  func testWhatIfResultsEmptyWithNoFavorites() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")

    XCTAssertTrue(meterStore.whatIfResults.isEmpty)
  }

  func testWhatIfResultCountMatchesFavorites() {
    let settings = MeterSettings.bengaluruDefault
    let delhiProfile = FareCatalog.entries.first {
      $0.profile.cityId == "delhi" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile
    let nycProfile = FareCatalog.entries.first { $0.profile.cityId == "nyc" }!.profile
    let chennaiProfile = FareCatalog.entries.first {
      $0.profile.cityId == "chennai" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile

    let favorites = [
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi),
      WhatIfFavorite(cityId: "chennai", vehicleType: VehicleTypeCatalog.autoRickshaw),
    ]

    let profiles: [String: CityFareProfile] = [
      "delhi:\(VehicleTypeCatalog.autoRickshaw)": delhiProfile,
      "nyc:\(VehicleTypeCatalog.yellowTaxi)": nycProfile,
      "chennai:\(VehicleTypeCatalog.autoRickshaw)": chennaiProfile,
    ]

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      whatIfFavorites: favorites,
      whatIfProfileLookup: { fav in profiles[fav.id] }
    )

    XCTAssertEqual(meterStore.whatIfResults.count, 3)
  }

  // MARK: - WhatIf lifecycle

  func testWhatIfResultsClearedOnStopTrip() {
    let settings = MeterSettings.bengaluruDefault
    let delhiProfile = FareCatalog.entries.first {
      $0.profile.cityId == "delhi" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile
    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      whatIfFavorites: [favorite],
      whatIfProfileLookup: { _ in delhiProfile }
    )
    XCTAssertEqual(meterStore.whatIfResults.count, 1)

    meterStore.stopTrip(tripStore: tripStore)
    XCTAssertTrue(meterStore.whatIfResults.isEmpty)
  }

  func testWhatIfResultsClearedOnReset() {
    let settings = MeterSettings.bengaluruDefault
    let delhiProfile = FareCatalog.entries.first {
      $0.profile.cityId == "delhi" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw
    }!.profile
    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      whatIfFavorites: [favorite],
      whatIfProfileLookup: { _ in delhiProfile }
    )
    meterStore.stopTrip(tripStore: tripStore)
    meterStore.resetToForHire()

    XCTAssertTrue(meterStore.whatIfResults.isEmpty)
  }

  // MARK: - RateSnapshot fields

  func testRateSnapshotIncludesVehicleTypeAndCurrency() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      vehicleType: VehicleTypeCatalog.autoRickshaw,
      currencyCode: "INR"
    )
    meterStore.stopTrip(tripStore: tripStore)

    let trip = tripStore.trips.first
    XCTAssertNotNil(trip)
    XCTAssertEqual(trip?.rateSnapshot.vehicleType, VehicleTypeCatalog.autoRickshaw)
    XCTAssertEqual(trip?.rateSnapshot.currencyCode, "INR")
  }

  func testActiveCurrencyCodeSetOnStartTrip() {
    let settings = MeterSettings.bengaluruDefault

    XCTAssertEqual(meterStore.activeCurrencyCode, "INR")

    meterStore.startTrip(
      settings: settings,
      cityId: "nyc",
      cityName: "New York City",
      currencyCode: "USD"
    )
    XCTAssertEqual(meterStore.activeCurrencyCode, "USD")
  }

  func testActiveCurrencyCodeDefaultsToINR() {
    let settings = MeterSettings.bengaluruDefault

    meterStore.startTrip(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")
    XCTAssertEqual(meterStore.activeCurrencyCode, "INR")
  }

  func testActiveCurrencyCodeResetOnResetToForHire() {
    let settings = MeterSettings.bengaluruDefault
    meterStore.startTrip(settings: settings, cityId: "nyc", cityName: "NYC", currencyCode: "USD")
    XCTAssertEqual(meterStore.activeCurrencyCode, "USD")

    meterStore.stopTrip(tripStore: tripStore)
    meterStore.resetToForHire()
    XCTAssertEqual(meterStore.activeCurrencyCode, "INR")
  }

  // MARK: - Vehicle switching

  func testSwitchVehicleTypeNotOnTripIsNoOp() {
    let url = try! TestHelpers.makeTempURL(filename: "vt-switch.json")
    let settingsStore = SettingsStore(fileURL: url)

    // Should not crash
    meterStore.switchVehicleType(settingsStore: settingsStore)
    XCTAssertFalse(meterStore.isOnTrip)
  }

  func testSwitchVehicleTypeMidTripRecalculatesFare() async throws {
    let url = try TestHelpers.makeTempURL(filename: "vt-switch-mid.json")
    let settingsStore = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    // Start trip with bengaluru auto-rickshaw
    settingsStore.selectCity("bengaluru")
    let initialSettings = settingsStore.settings
    let initialProfile = settingsStore.activeProfileForCurrentSelection

    meterStore.startTrip(
      settings: initialSettings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      surcharges: initialProfile?.surcharges,
      vehicleType: initialProfile?.vehicleType,
      currencyCode: initialProfile?.cityKey.currencyCode
    )

    let initialFare = meterStore.fare

    // Switch to taxi-economy (higher rates)
    settingsStore.selectVehicleType(VehicleTypeCatalog.taxiEconomy)
    meterStore.switchVehicleType(settingsStore: settingsStore)

    // Fare should have been recalculated (at minimum, the min fare should change)
    // Auto-rickshaw minFare=36, taxi-economy minFare=100
    let newFare = meterStore.fare
    XCTAssertNotEqual(initialFare, newFare, "Fare should change after vehicle switch")
    XCTAssertGreaterThanOrEqual(newFare, 100, "Taxi economy min fare is 100")
  }

  // MARK: - SettingsStore activeProfileForCurrentSelection

  func testActiveProfileForCurrentSelection() async throws {
    let url = try TestHelpers.makeTempURL(filename: "active-profile.json")
    let settingsStore = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    // Default: bengaluru auto-rickshaw
    let defaultProfile = settingsStore.activeProfileForCurrentSelection
    XCTAssertNotNil(defaultProfile)
    XCTAssertEqual(defaultProfile?.cityId, "bengaluru")
    XCTAssertEqual(defaultProfile?.vehicleType, VehicleTypeCatalog.autoRickshaw)

    // Select taxi-economy
    settingsStore.selectVehicleType(VehicleTypeCatalog.taxiEconomy)
    let taxiProfile = settingsStore.activeProfileForCurrentSelection
    XCTAssertNotNil(taxiProfile)
    XCTAssertEqual(taxiProfile?.vehicleType, VehicleTypeCatalog.taxiEconomy)

    // Select different city
    settingsStore.selectCity("nyc")
    let nycProfile = settingsStore.activeProfileForCurrentSelection
    XCTAssertNotNil(nycProfile)
    XCTAssertEqual(nycProfile?.cityId, "nyc")
    XCTAssertEqual(nycProfile?.vehicleType, VehicleTypeCatalog.yellowTaxi)
  }

  // MARK: - WhatIf skips unfound favorites

  func testWhatIfSkipsUnfoundFavorites() {
    let settings = MeterSettings.bengaluruDefault
    let favorite = WhatIfFavorite(cityId: "nonexistent", vehicleType: "unknown")

    meterStore.startTrip(
      settings: settings,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      whatIfFavorites: [favorite],
      whatIfProfileLookup: { _ in nil }
    )

    XCTAssertTrue(meterStore.whatIfResults.isEmpty)
  }
}
