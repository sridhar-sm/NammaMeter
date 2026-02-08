import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class FareProfileTests: XCTestCase {
  func testNightWindowWrapAround() {
    let settings = MeterSettings.bengaluruDefault
    let calendar = Calendar.autoupdatingCurrent

    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3

    components.hour = 23
    let late = calendar.date(from: components)
    XCTAssertNotNil(late)
    XCTAssertTrue(settings.isNight(at: late!))

    components.hour = 4
    let early = calendar.date(from: components)
    XCTAssertNotNil(early)
    XCTAssertTrue(settings.isNight(at: early!))

    components.hour = 21
    let before = calendar.date(from: components)
    XCTAssertNotNil(before)
    XCTAssertFalse(settings.isNight(at: before!))

    components.hour = 5
    let end = calendar.date(from: components)
    XCTAssertNotNil(end)
    XCTAssertFalse(settings.isNight(at: end!))
  }

  func testProfileDecodingDefaultsNightWindow() throws {
    let json = """
    {
      "id": "test-1",
      "cityId": "test-city",
      "name": "Test City",
      "cityKey": {
        "city": "Test City",
        "region": null,
        "countryCode": "IN"
      },
      "rates": {
        "baseFare": 30,
        "perKmRate": 15,
        "perMinuteRate": 0,
        "includedKm": 2.0,
        "minFare": 30
      },
      "multipliers": {
        "night": 1.5
      },
      "waitCharges": {
        "freeWaitMinutes": 5,
        "waitIntervalMinutes": 15,
        "waitIntervalCharge": 5
      },
      "effectiveFrom": "2026-01-01T00:00:00Z"
    }
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let profile = try decoder.decode(CityFareProfile.self, from: data)

    XCTAssertEqual(profile.nightWindow.startHour, 22)
    XCTAssertEqual(profile.nightWindow.endHour, 5)
  }

  func testSettingsStoreSeedsCatalogOnFirstLoad() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count)
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId)
  }

  func testSettingsStoreAppendsCatalogUpdates() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: FareCatalog.defaultCityId,
      profiles: [FareCatalog.defaultProfile],
      catalogVersionApplied: max(FareCatalog.currentVersion - 1, 0)
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count)
  }

  func testSettingsStoreFallbacksToBengaluru() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let fallbackProfile = try XCTUnwrap(FareCatalog.entries.first { $0.profile.cityId != FareCatalog.defaultCityId }?.profile)
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: "unknown-city",
      profiles: [fallbackProfile],
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId)
    XCTAssertTrue(store.profiles.contains { $0.cityId == FareCatalog.defaultCityId })
  }

  func testCitySelectionUpdatesMeterSettings() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let bengaluruBaseFare = store.settings.baseFare
    store.selectCity("mandya")

    XCTAssertEqual(store.selectedCityId, "mandya")
    XCTAssertNotEqual(store.settings.baseFare, bengaluruBaseFare)
    XCTAssertEqual(store.settings.baseFare, 30)
  }

  func testAvailableCitiesReturnsLatestProfiles() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let cities = store.availableCities
    XCTAssertEqual(cities.count, FareCatalog.entries.count)
    XCTAssertTrue(cities.allSatisfy { city in
      cities.filter { $0.cityId == city.cityId }.count == 1
    })
  }

  func testAddCustomCity() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let initialCount = store.profiles.count

    let customProfile = CityFareProfile(
      id: UUID().uuidString,
      cityId: "custom-test",
      name: "Test City",
      cityKey: CityKey(city: "Test", region: nil, countryCode: "IN"),
      rates: FareRates(baseFare: 25, perKmRate: 12, perMinuteRate: 0, includedKm: 1.5, minFare: 25),
      multipliers: FareMultipliers(night: 1.5),
      nightWindow: NightFareWindow.defaultWindow,
      waitCharges: WaitingChargePolicy(freeWaitMinutes: 5, waitIntervalMinutes: 15, waitIntervalCharge: 5),
      effectiveFrom: Date()
    )

    store.addCity(customProfile)

    XCTAssertEqual(store.profiles.count, initialCount + 1)
    XCTAssertEqual(store.selectedCityId, "custom-test")
    XCTAssertEqual(store.settings.baseFare, 25)
  }

  func testRateSnapshotIncludesCityInfo() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")

    XCTAssertEqual(snapshot.cityId, "bengaluru")
    XCTAssertEqual(snapshot.cityName, "Bengaluru")
  }

  func testRateSnapshotBackwardCompatibility() throws {
    let json = """
    {
      "baseFare": 36,
      "perKmRate": 18,
      "perMinuteRate": 0,
      "includedKm": 2.0,
      "minFare": 36,
      "nightMultiplier": 1.5,
      "nightStartHour": 22,
      "nightEndHour": 5,
      "freeWaitMinutes": 5,
      "waitIntervalMinutes": 15,
      "waitIntervalCharge": 10
    }
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoder = JSONDecoder()
    let snapshot = try decoder.decode(RateSnapshot.self, from: data)

    XCTAssertNil(snapshot.cityId)
    XCTAssertNil(snapshot.cityName)
    XCTAssertEqual(snapshot.baseFare, 36)
  }

  func testActiveCityInfo() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let cityInfo = store.activeCityInfo
    XCTAssertEqual(cityInfo.cityId, FareCatalog.defaultCityId)
    XCTAssertEqual(cityInfo.cityName, "Bengaluru")

    store.selectCity("mysuru")
    let updatedInfo = store.activeCityInfo
    XCTAssertEqual(updatedInfo.cityId, "mysuru")
    XCTAssertEqual(updatedInfo.cityName, "Mysuru")
  }

  // MARK: - Migration Edge Cases

  func testMigrationHandlesEmptyProfilesList() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: nil,
      profiles: [],  // Empty profiles array
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // ensureMinimumProfile() should have added default profile
    XCTAssertFalse(store.profiles.isEmpty, "ensureMinimumProfile should add default profile when profiles array is empty")
    XCTAssertTrue(store.profiles.contains { $0.cityId == FareCatalog.defaultCityId }, "Default city should be added")
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId, "Default city should be selected")
  }

  func testMigrationNormalizesInvalidSelection() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")

    // Create a profile for Mandya but select non-existent city
    let mandyaProfile = try XCTUnwrap(FareCatalog.entries.first { $0.profile.cityId == "mandya" }?.profile)
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: "non-existent-city-id",
      profiles: [mandyaProfile],  // Only Mandya, not Bengaluru
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // normalizeSelection() should fallback to default city and add default profile if missing
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId, "Invalid selection should normalize to default city")
    XCTAssertTrue(store.profiles.contains { $0.cityId == FareCatalog.defaultCityId }, "Default profile should be added if missing")
    XCTAssertTrue(store.profiles.contains { $0.cityId == "mandya" }, "Original Mandya profile should be preserved")
  }

  func testMigrationOrderMatters() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")

    // Create scenario where migration order is critical:
    // Empty profiles + invalid selection
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: "some-city",  // Invalid selection
      profiles: [],  // Empty profiles
      catalogVersionApplied: 0  // Needs catalog update
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // All migrations should have run successfully in correct order:
    // 1. applyCatalogUpdatesIfNeeded() populates profiles
    // 2. ensureMinimumProfile() ensures at least one profile (redundant here but safe)
    // 3. normalizeSelection() validates and corrects selection
    XCTAssertFalse(store.profiles.isEmpty, "Catalog updates should populate profiles")
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId, "Selection should be normalized")
    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count, "All catalog profiles should be added")
  }

  func testCatalogVersionRollbackHandled() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")

    // Simulate scenario where user's catalogVersionApplied is higher than current
    // (e.g., downgrading app version or development scenario)
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: FareCatalog.defaultCityId,
      profiles: FareCatalog.entries.map(\.profile),
      catalogVersionApplied: FareCatalog.currentVersion + 10  // Future version
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // applyCatalogUpdatesIfNeeded() should handle gracefully (guard returns false)
    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count, "Profiles should remain unchanged")
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId, "Selection should remain valid")
    // Note: catalogVersionApplied remains at future version, which is safe
    // Future app versions will have catalogVersionApplied >= FareCatalog.currentVersion
  }

  func testSchemaVersionBumpIsIdempotent() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")

    // Create settings with current schema version
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: FareCatalog.defaultCityId,
      profiles: [FareCatalog.defaultProfile],
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try TestHelpers.write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // Load again to verify idempotency
    let store2 = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store2)

    // Schema version bump should be safe to run multiple times
    XCTAssertEqual(store2.profiles.count, 1, "Profiles should not duplicate on reload")
    XCTAssertEqual(store2.selectedCityId, FareCatalog.defaultCityId, "Selection should remain stable")

    // Verify old schema version also bumps correctly
    let oldSeed = FareProfileSettings(
      schemaVersion: 1,  // Old schema version
      selectedCityId: FareCatalog.defaultCityId,
      profiles: [FareCatalog.defaultProfile],
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try TestHelpers.write(settings: oldSeed, to: url)

    let store3 = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store3)

    XCTAssertEqual(store3.profiles.count, 1, "Schema version bump should not affect profiles")
    XCTAssertEqual(store3.selectedCityId, FareCatalog.defaultCityId, "Schema version bump should not affect selection")
  }

}
