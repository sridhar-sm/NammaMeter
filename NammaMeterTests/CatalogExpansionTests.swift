import Foundation
import XCTest
@testable import NammaMeter

final class CatalogExpansionTests: XCTestCase {

  // MARK: - Entry count

  func testCatalogHas22Entries() {
    XCTAssertEqual(FareCatalog.entries.count, 22, "5 existing + 11 Indian + 6 US = 22")
  }

  // MARK: - Unique IDs

  func testAllEntriesHaveUniqueIds() {
    let ids = FareCatalog.entries.map(\.profile.id)
    let uniqueIds = Set(ids)
    XCTAssertEqual(ids.count, uniqueIds.count, "Duplicate IDs found: \(ids.filter { id in ids.filter { $0 == id }.count > 1 })")
  }

  // MARK: - Version 3 entries

  func testVersion3EntriesCount() {
    let v3 = FareCatalog.entries.filter { $0.introducedInVersion == 3 }
    XCTAssertEqual(v3.count, 17, "11 Indian + 6 US = 17 new entries")
  }

  func testVersion2EntriesUnchanged() {
    let v2 = FareCatalog.entries.filter { $0.introducedInVersion == 2 }
    XCTAssertEqual(v2.count, 5, "Original 5 Karnataka entries")
  }

  // MARK: - NYC surcharges

  func testNYCHasFourSurcharges() {
    let nyc = FareCatalog.entries.first { $0.profile.cityId == "nyc" }
    XCTAssertNotNil(nyc)
    XCTAssertEqual(nyc!.profile.surcharges?.count, 4)

    let ids = nyc!.profile.surcharges!.map(\.id)
    XCTAssertTrue(ids.contains("nyc-night"))
    XCTAssertTrue(ids.contains("nyc-rush"))
    XCTAssertTrue(ids.contains("nyc-mta"))
    XCTAssertTrue(ids.contains("nyc-improvement"))
  }

  func testNYCSpeedBasedSwitching() {
    let nyc = FareCatalog.entries.first { $0.profile.cityId == "nyc" }!
    XCTAssertEqual(nyc.profile.rates.perMinuteWhenSlow!, 0.70, accuracy: 0.001)
    XCTAssertEqual(nyc.profile.rates.slowSpeedThresholdKph!, 19, accuracy: 0.1)
  }

  // MARK: - Speed-based cities

  func testSpeedBasedCities() {
    let speedCityIds = ["nyc", "chicago", "dallas", "philadelphia", "la"]
    for cityId in speedCityIds {
      let entry = FareCatalog.entries.first { $0.profile.cityId == cityId }
      XCTAssertNotNil(entry, "Missing entry for \(cityId)")
      XCTAssertNotNil(entry!.profile.rates.perMinuteWhenSlow, "\(cityId) should have perMinuteWhenSlow")
      XCTAssertNotNil(entry!.profile.rates.slowSpeedThresholdKph, "\(cityId) should have slowSpeedThresholdKph")
    }
  }

  func testSeattleNoSpeedSwitch() {
    let seattle = FareCatalog.entries.first { $0.profile.cityId == "seattle" }
    XCTAssertNotNil(seattle)
    XCTAssertNil(seattle!.profile.rates.perMinuteWhenSlow)
    XCTAssertNil(seattle!.profile.rates.slowSpeedThresholdKph)
    XCTAssertEqual(seattle!.profile.waitCharges.waitIntervalCharge, 7.50, accuracy: 0.01)
  }

  // MARK: - Indian cities

  func testDelhiHasThreeVehicleTypes() {
    let delhi = FareCatalog.entries.filter { $0.profile.cityId == "delhi" }
    XCTAssertEqual(delhi.count, 3)
    let types = Set(delhi.map(\.profile.vehicleType))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.autoRickshaw))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.taxiNonAC))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.taxiAC))
  }

  func testBengaluruHasFourVehicleTypes() {
    let bengaluru = FareCatalog.entries.filter { $0.profile.cityId == "bengaluru" }
    XCTAssertEqual(bengaluru.count, 4)
    let types = Set(bengaluru.map(\.profile.vehicleType))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.autoRickshaw))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.taxiEconomy))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.taxiMidrange))
    XCTAssertTrue(types.contains(VehicleTypeCatalog.taxiPremium))
  }

  // MARK: - Currency codes

  func testIndianEntriesUseINR() {
    let indian = FareCatalog.entries.filter { $0.profile.cityKey.countryCode == "IN" }
    for entry in indian {
      XCTAssertEqual(entry.profile.cityKey.currencyCode, "INR", "\(entry.profile.name) should use INR")
    }
  }

  func testUSEntriesUseUSD() {
    let us = FareCatalog.entries.filter { $0.profile.cityKey.countryCode == "US" }
    XCTAssertEqual(us.count, 6)
    for entry in us {
      XCTAssertEqual(entry.profile.cityKey.currencyCode, "USD", "\(entry.profile.name) should use USD")
    }
  }

  // MARK: - Default profile unchanged

  func testDefaultProfileIsBengaluruAutoRickshaw() {
    let def = FareCatalog.defaultProfile
    XCTAssertEqual(def.cityId, "bengaluru")
    XCTAssertEqual(def.vehicleType, VehicleTypeCatalog.autoRickshaw)
    XCTAssertEqual(def.rates.baseFare, 36, accuracy: 0.01)
  }

  // MARK: - Catalog version

  func testCurrentVersionIs3() {
    XCTAssertEqual(FareCatalog.currentVersion, 3)
  }

  // MARK: - Migration simulation

  @MainActor
  func testCatalogMigrationAppendsNewEntries() async throws {
    let url = try TestHelpers.makeTempURL(filename: "migration-test.json")

    // Simulate existing state at catalog version 2
    let existingSettings = FareProfileSettings(
      schemaVersion: 3,
      selectedCityId: "bengaluru",
      profiles: FareCatalog.entries.filter { $0.introducedInVersion <= 2 }.map(\.profile),
      catalogVersionApplied: 2
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(existingSettings)
    try data.write(to: url)

    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    // Should have all 22 profiles now
    XCTAssertEqual(store.profiles.count, 22)
    // Should not have duplicated existing IDs
    let ids = store.profiles.map(\.id)
    XCTAssertEqual(ids.count, Set(ids).count)
  }
}
