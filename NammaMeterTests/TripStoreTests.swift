import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class TripStoreTests: XCTestCase {

  // MARK: - Add Tests

  func testAddTripInsertsAtFront() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip1 = TestHelpers.makeTrip(fare: 100)
    let trip2 = TestHelpers.makeTrip(fare: 200)

    store.add(trip1)
    store.add(trip2)

    XCTAssertEqual(store.trips.count, 2)
    XCTAssertEqual(store.trips[0].id, trip2.id, "Most recent trip should be first")
    XCTAssertEqual(store.trips[1].id, trip1.id)
  }

  // MARK: - Delete Tests

  func testDeleteAtOffsets() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip1 = TestHelpers.makeTrip(fare: 100)
    let trip2 = TestHelpers.makeTrip(fare: 200)
    let trip3 = TestHelpers.makeTrip(fare: 300)

    store.add(trip1)
    store.add(trip2)
    store.add(trip3)

    // Delete middle item (index 1)
    store.delete(at: IndexSet(integer: 1))

    XCTAssertEqual(store.trips.count, 2)
    XCTAssertEqual(store.trips[0].fare, 300) // trip3 (first)
    XCTAssertEqual(store.trips[1].fare, 100) // trip1 (last)
  }

  func testDeleteAtMultipleOffsets() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trips = (0..<5).map { TestHelpers.makeTrip(fare: Double($0 * 100)) }
    trips.forEach { store.add($0) }

    // Delete indices 1 and 3
    store.delete(at: IndexSet([1, 3]))

    XCTAssertEqual(store.trips.count, 3)
  }

  func testDeleteByIds() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip1 = TestHelpers.makeTrip(fare: 100)
    let trip2 = TestHelpers.makeTrip(fare: 200)
    let trip3 = TestHelpers.makeTrip(fare: 300)

    store.add(trip1)
    store.add(trip2)
    store.add(trip3)

    store.delete(ids: Set([trip1.id, trip3.id]))

    XCTAssertEqual(store.trips.count, 1)
    XCTAssertEqual(store.trips[0].id, trip2.id)
  }

  func testDeleteByEmptyIdsDoesNothing() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip = TestHelpers.makeTrip(fare: 100)
    store.add(trip)

    store.delete(ids: Set())

    XCTAssertEqual(store.trips.count, 1)
  }

  func testDeleteAll() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trips = (0..<5).map { TestHelpers.makeTrip(fare: Double($0 * 100)) }
    trips.forEach { store.add($0) }

    store.deleteAll()

    XCTAssertTrue(store.trips.isEmpty)
  }

  // MARK: - Update Tests

  func testUpdateTrip() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip = TestHelpers.makeTrip(fare: 100)
    store.add(trip)

    store.update(trip.id) { $0.name = "Updated Name" }

    XCTAssertEqual(store.trips[0].name, "Updated Name")
  }

  func testUpdateNonExistentTripDoesNothing() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip = TestHelpers.makeTrip(fare: 100)
    store.add(trip)

    let nonExistentId = UUID()
    store.update(nonExistentId) { $0.name = "Should Not Update" }

    XCTAssertNil(store.trips[0].name)
  }

  // MARK: - Lookup Tests

  func testTripForId() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip1 = TestHelpers.makeTrip(fare: 100)
    let trip2 = TestHelpers.makeTrip(fare: 200)

    store.add(trip1)
    store.add(trip2)

    let found = store.trip(for: trip1.id)
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.fare, 100)
  }

  func testTripForIdReturnsNilForUnknown() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    let trip = TestHelpers.makeTrip(fare: 100)
    store.add(trip)

    let found = store.trip(for: UUID())
    XCTAssertNil(found)
  }

  // MARK: - Persistence Tests

  func testTripsPersistedAndLoaded() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")

    // Create store and add trips
    let store1 = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store1)

    let trip1 = TestHelpers.makeTrip(fare: 100, name: "Trip One")
    let trip2 = TestHelpers.makeTrip(fare: 200, name: "Trip Two")
    store1.add(trip1)
    store1.add(trip2)

    // Wait for save to complete
    try await Task.sleep(for: .milliseconds(200))

    // Create new store from same file
    let store2 = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store2)

    XCTAssertEqual(store2.trips.count, 2)
    XCTAssertEqual(store2.trips[0].name, "Trip Two")
    XCTAssertEqual(store2.trips[1].name, "Trip One")
  }

  func testEmptyFileReturnsEmptyArray() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")
    // File doesn't exist - should load as empty

    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    XCTAssertTrue(store.trips.isEmpty)
  }

  func testCorruptedFileHandledGracefully() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")

    // Write invalid JSON to file
    let corruptedData = "not valid json".data(using: .utf8)!
    try corruptedData.write(to: url)

    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    // Should gracefully handle and return empty
    XCTAssertTrue(store.trips.isEmpty)
  }

  func testPartiallyCorruptedJsonHandledGracefully() async throws {
    let url = try TestHelpers.makeTempURL(filename: "trips-test.json")

    // Write JSON that's valid but wrong schema
    let wrongSchema = "[{\"wrong\": \"schema\"}]".data(using: .utf8)!
    try wrongSchema.write(to: url)

    let store = TripStore(fileURL: url)
    await TestHelpers.waitForTripStoreLoad(store)

    // Should gracefully handle and return empty
    XCTAssertTrue(store.trips.isEmpty)
  }

}
