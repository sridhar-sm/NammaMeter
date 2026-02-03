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
    let url = try makeTempURL()
    let store = SettingsStore(fileURL: url)
    await waitForProfiles(store)

    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count)
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId)
  }

  func testSettingsStoreAppendsCatalogUpdates() async throws {
    let url = try makeTempURL()
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: FareCatalog.defaultCityId,
      profiles: [FareCatalog.defaultProfile],
      catalogVersionApplied: max(FareCatalog.currentVersion - 1, 0)
    )
    try write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await waitForProfiles(store)

    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count)
  }

  func testSettingsStoreFallbacksToBengaluru() async throws {
    let url = try makeTempURL()
    let fallbackProfile = try XCTUnwrap(FareCatalog.entries.first { $0.profile.cityId != FareCatalog.defaultCityId }?.profile)
    let seed = FareProfileSettings(
      schemaVersion: FareProfileSettings.currentSchemaVersion,
      selectedCityId: "unknown-city",
      profiles: [fallbackProfile],
      catalogVersionApplied: FareCatalog.currentVersion
    )
    try write(settings: seed, to: url)

    let store = SettingsStore(fileURL: url)
    await waitForProfiles(store)

    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId)
    XCTAssertTrue(store.profiles.contains { $0.cityId == FareCatalog.defaultCityId })
  }

  private func makeTempURL() throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("fare-profiles.json")
  }

  private func write(settings: FareProfileSettings, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(settings)
    try data.write(to: url, options: [.atomic])
  }

  private func waitForProfiles(_ store: SettingsStore) async {
    for _ in 0..<60 {
      if !store.profiles.isEmpty {
        return
      }
      try? await Task.sleep(for: .milliseconds(50))
    }
    XCTFail("Timed out waiting for SettingsStore to load")
  }
}
