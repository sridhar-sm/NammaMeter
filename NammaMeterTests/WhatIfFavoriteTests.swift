import Foundation
import XCTest
@testable import NammaMeter

final class WhatIfFavoriteTests: XCTestCase {

  // MARK: - WhatIfFavorite identity

  func testFavoriteId() {
    let fav = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    XCTAssertEqual(fav.id, "nyc:yellow-taxi")
  }

  func testFavoriteEquality() {
    let a = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    let b = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    let c = WhatIfFavorite(cityId: "nyc", vehicleType: "taxi")
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  // MARK: - Codable

  func testFavoriteCodableRoundTrip() throws {
    let fav = WhatIfFavorite(cityId: "chicago", vehicleType: "taxi")
    let data = try JSONEncoder().encode(fav)
    let decoded = try JSONDecoder().decode(WhatIfFavorite.self, from: data)
    XCTAssertEqual(fav, decoded)
  }

  // MARK: - FareProfileSettings decode without favorites

  func testFareProfileSettingsDecodesWithoutFavorites() throws {
    let json = """
    {
      "schemaVersion": 3,
      "selectedCityId": "bengaluru",
      "profiles": [],
      "catalogVersionApplied": 2
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let settings = try JSONDecoder().decode(FareProfileSettings.self, from: data)
    XCTAssertTrue(settings.whatIfFavorites.isEmpty)
  }

  func testFareProfileSettingsDecodesWithFavorites() throws {
    let json = """
    {
      "schemaVersion": 3,
      "selectedCityId": "bengaluru",
      "profiles": [],
      "catalogVersionApplied": 2,
      "whatIfFavorites": [
        { "cityId": "nyc", "vehicleType": "yellow-taxi" }
      ]
    }
    """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let settings = try JSONDecoder().decode(FareProfileSettings.self, from: data)
    XCTAssertEqual(settings.whatIfFavorites.count, 1)
    XCTAssertEqual(settings.whatIfFavorites[0].cityId, "nyc")
  }

  func testFareProfileSettingsRoundTripWithFavorites() throws {
    let settings = FareProfileSettings(
      schemaVersion: 3,
      selectedCityId: "bengaluru",
      profiles: [],
      catalogVersionApplied: 2,
      whatIfFavorites: [
        WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi"),
        WhatIfFavorite(cityId: "chicago", vehicleType: "taxi"),
      ]
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(settings)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(FareProfileSettings.self, from: data)
    XCTAssertEqual(decoded.whatIfFavorites.count, 2)
    XCTAssertEqual(decoded.whatIfFavorites[0].id, "nyc:yellow-taxi")
  }

  // MARK: - SettingsStore favorites API

  @MainActor
  func testAddFavorite() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let fav = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    store.addWhatIfFavorite(fav)

    XCTAssertEqual(store.whatIfFavorites.count, 1)
    XCTAssertEqual(store.whatIfFavorites[0].id, "nyc:yellow-taxi")
  }

  @MainActor
  func testRemoveFavorite() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let fav = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    store.addWhatIfFavorite(fav)
    XCTAssertEqual(store.whatIfFavorites.count, 1)

    store.removeWhatIfFavorite(fav)
    XCTAssertTrue(store.whatIfFavorites.isEmpty)
  }

  @MainActor
  func testDuplicatePrevention() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let fav = WhatIfFavorite(cityId: "nyc", vehicleType: "yellow-taxi")
    store.addWhatIfFavorite(fav)
    store.addWhatIfFavorite(fav)

    XCTAssertEqual(store.whatIfFavorites.count, 1)
  }

  @MainActor
  func testMax3Favorites() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    store.addWhatIfFavorite(WhatIfFavorite(cityId: "a", vehicleType: "taxi"))
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "b", vehicleType: "taxi"))
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "c", vehicleType: "taxi"))
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "d", vehicleType: "taxi"))

    XCTAssertEqual(store.whatIfFavorites.count, 3)
  }

  @MainActor
  func testWhatIfProfileLookup() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let fav = WhatIfFavorite(cityId: "bengaluru", vehicleType: VehicleTypeCatalog.autoRickshaw)
    let profile = store.whatIfProfile(for: fav)
    XCTAssertNotNil(profile)
    XCTAssertEqual(profile?.cityId, "bengaluru")
    XCTAssertEqual(profile?.vehicleType, VehicleTypeCatalog.autoRickshaw)
  }

  @MainActor
  func testWhatIfProfileLookupMissing() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fare-profiles.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let fav = WhatIfFavorite(cityId: "nonexistent", vehicleType: "taxi")
    let profile = store.whatIfProfile(for: fav)
    XCTAssertNil(profile)
  }
}
