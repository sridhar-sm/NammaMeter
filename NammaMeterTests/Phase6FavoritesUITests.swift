import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class Phase6FavoritesUITests: XCTestCase {

  // MARK: - Favorite toggle behavior (simulating CityDetailView actions)

  func testFavoriteToggleAddsAndRemoves() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fav-toggle.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)
    XCTAssertFalse(store.whatIfFavorites.contains { $0.id == favorite.id })

    // Add favorite (simulates star tap)
    store.addWhatIfFavorite(favorite)
    XCTAssertTrue(store.whatIfFavorites.contains { $0.id == favorite.id })
    XCTAssertEqual(store.whatIfFavorites.count, 1)

    // Remove favorite (simulates star tap again)
    store.removeWhatIfFavorite(favorite)
    XCTAssertFalse(store.whatIfFavorites.contains { $0.id == favorite.id })
    XCTAssertEqual(store.whatIfFavorites.count, 0)
  }

  func testMaxThreeFavoritesDisablesAdditionalStars() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fav-max.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // Add 3 favorites
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw))
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi))
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "chennai", vehicleType: VehicleTypeCatalog.autoRickshaw))
    XCTAssertEqual(store.whatIfFavorites.count, 3)

    // 4th add silently ignored (UI would show disabled star)
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "seattle", vehicleType: VehicleTypeCatalog.taxi))
    XCTAssertEqual(store.whatIfFavorites.count, 3)
    XCTAssertFalse(store.whatIfFavorites.contains { $0.cityId == "seattle" })

    // Can still remove existing favorite
    store.removeWhatIfFavorite(WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw))
    XCTAssertEqual(store.whatIfFavorites.count, 2)

    // Now can add again
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "seattle", vehicleType: VehicleTypeCatalog.taxi))
    XCTAssertEqual(store.whatIfFavorites.count, 3)
    XCTAssertTrue(store.whatIfFavorites.contains { $0.cityId == "seattle" })
  }

  func testCityHasFavoriteCheck() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fav-city.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    // No favorites initially
    XCTAssertFalse(store.whatIfFavorites.contains { $0.cityId == "delhi" })

    // Add a Delhi favorite
    store.addWhatIfFavorite(WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw))

    // CityRow check: city has at least one favorite
    XCTAssertTrue(store.whatIfFavorites.contains { $0.cityId == "delhi" })
    XCTAssertFalse(store.whatIfFavorites.contains { $0.cityId == "nyc" })
  }

  func testDuplicateFavoriteNotAdded() async throws {
    let url = try TestHelpers.makeTempURL(filename: "fav-dup.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)

    let favorite = WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)
    store.addWhatIfFavorite(favorite)
    store.addWhatIfFavorite(favorite) // duplicate
    XCTAssertEqual(store.whatIfFavorites.count, 1)
  }
}
