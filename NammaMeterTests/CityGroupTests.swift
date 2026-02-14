import Foundation
import XCTest
@testable import NammaMeter

final class CityGroupTests: XCTestCase {

  // MARK: - availableCityGroups

  @MainActor
  func testAvailableCityGroupsCount() async throws {
    let url = try TestHelpers.makeTempURL(filename: "groups-test.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    let groups = store.availableCityGroups
    // 5 existing Karnataka cities + 4 new Indian cities + 6 US cities = 15 unique cityIds
    // Bengaluru (4 types), Mandya (1), Mysuru (1), DK (1), Udupi (1),
    // Delhi (3), Hyderabad (2), Chennai (2), Kolkata (1),
    // NYC (1), Seattle (1), Chicago (1), Dallas (1), Philadelphia (1), LA (1)
    XCTAssertEqual(groups.count, 15)
  }

  @MainActor
  func testBengaluruGroupHasFourVehicleTypes() async throws {
    let url = try TestHelpers.makeTempURL(filename: "groups-blr.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    let bengaluru = store.availableCityGroups.first { $0.cityId == "bengaluru" }
    XCTAssertNotNil(bengaluru)
    XCTAssertEqual(bengaluru!.vehicleTypes.count, 4)
    XCTAssertTrue(bengaluru!.vehicleTypes.contains(VehicleTypeCatalog.autoRickshaw))
    XCTAssertTrue(bengaluru!.vehicleTypes.contains(VehicleTypeCatalog.taxiEconomy))
  }

  @MainActor
  func testDelhiGroupHasThreeVehicleTypes() async throws {
    let url = try TestHelpers.makeTempURL(filename: "groups-del.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    let delhi = store.availableCityGroups.first { $0.cityId == "delhi" }
    XCTAssertNotNil(delhi)
    XCTAssertEqual(delhi!.vehicleTypes.count, 3)
  }

  @MainActor
  func testGroupsSortedAlphabetically() async throws {
    let url = try TestHelpers.makeTempURL(filename: "groups-sort.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    let names = store.availableCityGroups.map(\.name)
    XCTAssertEqual(names, names.sorted())
  }

  // MARK: - selectedVehicleType

  @MainActor
  func testSelectVehicleTypePersists() async throws {
    let url = try TestHelpers.makeTempURL(filename: "vt-select.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    XCTAssertNil(store.selectedVehicleType)

    store.selectVehicleType(VehicleTypeCatalog.taxiEconomy)
    XCTAssertEqual(store.selectedVehicleType, VehicleTypeCatalog.taxiEconomy)
  }

  @MainActor
  func testSelectCityResetsVehicleType() async throws {
    let url = try TestHelpers.makeTempURL(filename: "vt-reset.json")
    let store = SettingsStore(fileURL: url)
    try await Task.sleep(for: .milliseconds(500))

    store.selectVehicleType(VehicleTypeCatalog.taxiEconomy)
    XCTAssertEqual(store.selectedVehicleType, VehicleTypeCatalog.taxiEconomy)

    store.selectCity("delhi")
    XCTAssertNil(store.selectedVehicleType)
  }

  // MARK: - selectedVehicleType in FareProfileSettings Codable

  func testSelectedVehicleTypeRoundTrip() throws {
    let settings = FareProfileSettings(
      schemaVersion: 3,
      selectedCityId: "bengaluru",
      profiles: [FareCatalog.defaultProfile],
      catalogVersionApplied: 3,
      selectedVehicleType: VehicleTypeCatalog.taxiEconomy
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(settings)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(FareProfileSettings.self, from: data)

    XCTAssertEqual(decoded.selectedVehicleType, VehicleTypeCatalog.taxiEconomy)
  }

  func testSelectedVehicleTypeDefaultsToNil() throws {
    // Simulate old JSON without selectedVehicleType
    let json = """
    {
      "schemaVersion": 3,
      "selectedCityId": "bengaluru",
      "profiles": [],
      "catalogVersionApplied": 2,
      "whatIfFavorites": []
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(FareProfileSettings.self, from: json.data(using: .utf8)!)
    XCTAssertNil(decoded.selectedVehicleType)
  }

  // MARK: - CityGroup identity

  func testCityGroupIdentity() {
    let group = CityGroup(
      cityId: "bengaluru",
      name: "Bengaluru",
      cityKey: CityKey(city: "Bengaluru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
      vehicleTypes: [VehicleTypeCatalog.autoRickshaw]
    )
    XCTAssertEqual(group.id, "bengaluru")
  }

  // MARK: - VehicleTypeCatalog.allTypes

  func testAllTypesContainsAllKnownTypes() {
    let allTypes = VehicleTypeCatalog.allTypes
    XCTAssertEqual(allTypes.count, 11)
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.autoRickshaw))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxi))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.yellowTaxi))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxiAC))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxiNonAC))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxiEconomy))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxiMidrange))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.taxiPremium))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.cityTaxi))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.cab))
    XCTAssertTrue(allTypes.contains(VehicleTypeCatalog.tuktuk))
  }
}
