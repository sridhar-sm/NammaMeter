import XCTest
@testable import NammaMeter

@MainActor
final class ForHireFareRulesTests: XCTestCase {

  // MARK: - Helpers

  private func makeStore(favorites: [WhatIfFavorite] = []) async throws -> SettingsStore {
    let url = try TestHelpers.makeTempURL(filename: "forhire-rules.json")
    let store = SettingsStore(fileURL: url)
    await TestHelpers.waitForProfiles(store)
    for fav in favorites {
      store.addWhatIfFavorite(fav)
    }
    return store
  }

  private var bengaluruProfile: CityFareProfile {
    FareCatalog.entries.first(where: { $0.profile.cityId == "bengaluru" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw })!.profile
  }

  // MARK: - ForHire page list computation

  func testForHirePagesIncludesCurrentAndFavorites() async throws {
    let store = try await makeStore(favorites: [
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi)
    ])

    // Select a city so activeProfileForCurrentSelection is non-nil
    store.selectCity("bengaluru")

    let currentProfile = store.activeProfileForCurrentSelection
    XCTAssertNotNil(currentProfile, "Should have a current profile for bengaluru")

    // Build page list: current + 2 favorites
    var pages: [(id: String, profile: CityFareProfile)] = []
    if let profile = store.activeProfileForCurrentSelection {
      pages.append((id: "current", profile: profile))
    }
    for fav in store.whatIfFavorites {
      if let profile = store.whatIfProfile(for: fav) {
        pages.append((id: fav.id, profile: profile))
      }
    }

    XCTAssertEqual(pages.count, 3, "current + 2 favorites")
    XCTAssertEqual(pages[0].id, "current")
    XCTAssertEqual(pages[1].id, "delhi:auto-rickshaw")
    XCTAssertEqual(pages[2].id, "nyc:yellow-taxi")
  }

  func testForHirePagesSkipsFavoritesWithNoProfile() async throws {
    let store = try await makeStore(favorites: [
      WhatIfFavorite(cityId: "nonexistent-city", vehicleType: "unknown-vehicle"),
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw)
    ])

    store.selectCity("bengaluru")

    var pages: [(id: String, profile: CityFareProfile)] = []
    if let profile = store.activeProfileForCurrentSelection {
      pages.append((id: "current", profile: profile))
    }
    for fav in store.whatIfFavorites {
      if let profile = store.whatIfProfile(for: fav) {
        pages.append((id: fav.id, profile: profile))
      }
    }

    // nonexistent-city favorite should be skipped
    XCTAssertEqual(pages.count, 2, "current + 1 valid favorite (invalid skipped)")
    XCTAssertEqual(pages[0].id, "current")
    XCTAssertEqual(pages[1].id, "delhi:auto-rickshaw")
  }

  func testForHirePagesWithNoFavorites() async throws {
    let store = try await makeStore()

    store.selectCity("bengaluru")

    var pages: [(id: String, profile: CityFareProfile)] = []
    if let profile = store.activeProfileForCurrentSelection {
      pages.append((id: "current", profile: profile))
    }
    for fav in store.whatIfFavorites {
      if let profile = store.whatIfProfile(for: fav) {
        pages.append((id: fav.id, profile: profile))
      }
    }

    XCTAssertEqual(pages.count, 1, "Only current profile, no favorites")
    XCTAssertEqual(pages[0].id, "current")
  }

  func testPageCountForHireState() async throws {
    let store = try await makeStore(favorites: [
      WhatIfFavorite(cityId: "delhi", vehicleType: VehicleTypeCatalog.autoRickshaw),
      WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi)
    ])

    store.selectCity("bengaluru")

    // forHire page count = 1 (map) + forHirePages.count
    var forHirePages: [(id: String, profile: CityFareProfile)] = []
    if let profile = store.activeProfileForCurrentSelection {
      forHirePages.append((id: "current", profile: profile))
    }
    for fav in store.whatIfFavorites {
      if let profile = store.whatIfProfile(for: fav) {
        forHirePages.append((id: fav.id, profile: profile))
      }
    }

    let pageCount = 1 + forHirePages.count
    XCTAssertEqual(pageCount, 4, "map + current + 2 favorites")
  }

  // MARK: - Fare rules preview content

  func testFareRulesPreviewUsesAllRulesFromProfile() {
    let rules = FareRuleEvaluator.allRules(from: bengaluruProfile)

    XCTAssertFalse(rules.isEmpty, "Bengaluru profile should produce fare rules")
    XCTAssertTrue(rules.contains { $0.kind == .baseFare }, "Should have base fare rule")
    XCTAssertTrue(rules.contains { $0.kind == .distanceCharge }, "Should have distance charge rule")
    XCTAssertTrue(rules.contains { $0.kind == .minimumFare }, "Should have minimum fare rule")

    // Verify each rule has a label and description
    for rule in rules {
      XCTAssertFalse(rule.label.isEmpty, "Rule \(rule.id) should have a label")
      XCTAssertFalse(rule.description.isEmpty, "Rule \(rule.id) should have a description")
    }
  }

  func testFareRulesForFavoriteProfile() async throws {
    let store = try await makeStore(favorites: [
      WhatIfFavorite(cityId: "nyc", vehicleType: VehicleTypeCatalog.yellowTaxi)
    ])

    let fav = store.whatIfFavorites[0]
    let profile = store.whatIfProfile(for: fav)
    XCTAssertNotNil(profile, "Should resolve NYC yellow taxi profile")

    let rules = FareRuleEvaluator.allRules(from: profile!)
    XCTAssertTrue(rules.contains { $0.kind == .baseFare })
    XCTAssertTrue(rules.contains { $0.kind == .speedBasedCharge }, "NYC uses speed-based charging")
  }
}
