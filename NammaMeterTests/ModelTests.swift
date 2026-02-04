import Foundation
import XCTest
@testable import NammaMeter

final class ModelTests: XCTestCase {

  // MARK: - MeterSettings.isNight() Tests

  func testIsNightSameStartEndHourReturnsFalse() {
    var settings = MeterSettings.bengaluruDefault
    settings.nightStartHour = 22
    settings.nightEndHour = 22

    let calendar = Calendar.autoupdatingCurrent
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3

    // Should return false for all hours when start == end
    for hour in 0..<24 {
      components.hour = hour
      let date = calendar.date(from: components)!
      XCTAssertFalse(settings.isNight(at: date), "Hour \(hour) should not be night when start == end")
    }
  }

  func testIsNightSameDayWindow() {
    // Daytime window: 8am to 5pm (simulating opposite of night)
    var settings = MeterSettings.bengaluruDefault
    settings.nightStartHour = 8
    settings.nightEndHour = 17

    let calendar = Calendar.autoupdatingCurrent
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3

    // Within window (8-16) should be night
    let withinWindowHours = [8, 9, 12, 15, 16]
    for hour in withinWindowHours {
      components.hour = hour
      let date = calendar.date(from: components)!
      XCTAssertTrue(settings.isNight(at: date), "Hour \(hour) should be night")
    }

    // Outside window (0-7, 17-23) should not be night
    let outsideWindowHours = [0, 5, 7, 17, 18, 23]
    for hour in outsideWindowHours {
      components.hour = hour
      let date = calendar.date(from: components)!
      XCTAssertFalse(settings.isNight(at: date), "Hour \(hour) should not be night")
    }
  }

  func testIsNightBoundaryConditions() {
    // Default Bengaluru: 22:00 to 05:00
    let settings = MeterSettings.bengaluruDefault

    let calendar = Calendar.autoupdatingCurrent
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3

    // Exactly at start hour (22) - should be night
    components.hour = 22
    XCTAssertTrue(settings.isNight(at: calendar.date(from: components)!))

    // One hour before start (21) - should not be night
    components.hour = 21
    XCTAssertFalse(settings.isNight(at: calendar.date(from: components)!))

    // Exactly at end hour (5) - should NOT be night (exclusive end)
    components.hour = 5
    XCTAssertFalse(settings.isNight(at: calendar.date(from: components)!))

    // One hour before end (4) - should be night
    components.hour = 4
    XCTAssertTrue(settings.isNight(at: calendar.date(from: components)!))
  }

  func testIsNightMidnightEdgeCases() {
    let calendar = Calendar.autoupdatingCurrent
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3
    components.hour = 0

    let midnight = calendar.date(from: components)!

    // Default (22-5): midnight should be night
    let defaultSettings = MeterSettings.bengaluruDefault
    XCTAssertTrue(defaultSettings.isNight(at: midnight))

    // Window starting at midnight (0-6)
    var startMidnight = MeterSettings.bengaluruDefault
    startMidnight.nightStartHour = 0
    startMidnight.nightEndHour = 6
    XCTAssertTrue(startMidnight.isNight(at: midnight))

    // Window ending at midnight (20-0) - hour 0 is end, exclusive
    var endMidnight = MeterSettings.bengaluruDefault
    endMidnight.nightStartHour = 20
    endMidnight.nightEndHour = 0
    XCTAssertFalse(endMidnight.isNight(at: midnight))

    // Hour 23 with (20-0) window should be night
    components.hour = 23
    XCTAssertTrue(endMidnight.isNight(at: calendar.date(from: components)!))
  }

  func testIsNightWrapAroundAllHours() {
    // Comprehensive test: 22:00 to 05:00
    let settings = MeterSettings.bengaluruDefault

    let calendar = Calendar.autoupdatingCurrent
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 3

    let expectedNightHours = Set([22, 23, 0, 1, 2, 3, 4])
    let expectedDayHours = Set([5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])

    for hour in 0..<24 {
      components.hour = hour
      let date = calendar.date(from: components)!
      let isNight = settings.isNight(at: date)

      if expectedNightHours.contains(hour) {
        XCTAssertTrue(isNight, "Hour \(hour) should be night")
      } else {
        XCTAssertFalse(isNight, "Hour \(hour) should not be night")
      }
    }
  }

  // MARK: - TripConditions Tests

  func testTripConditionsMultiplierWithNight() {
    let settings = MeterSettings.bengaluruDefault
    let conditions = TripConditions(isNight: true)

    XCTAssertEqual(conditions.multiplier(using: settings), settings.nightMultiplier)
    XCTAssertEqual(conditions.multiplier(using: settings), 1.5)
  }

  func testTripConditionsMultiplierWithoutNight() {
    let settings = MeterSettings.bengaluruDefault
    let conditions = TripConditions(isNight: false)

    XCTAssertEqual(conditions.multiplier(using: settings), 1.0)
  }

  func testTripConditionsClear() {
    XCTAssertFalse(TripConditions.clear.isNight)
  }

  // MARK: - TripConditions Codable Tests

  func testTripConditionsEncodeDecode() throws {
    let conditions = TripConditions(isNight: true)

    let encoder = JSONEncoder()
    let data = try encoder.encode(conditions)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TripConditions.self, from: data)

    XCTAssertEqual(decoded, conditions)
  }

  func testTripConditionsDecodingIgnoresLegacyFields() throws {
    // Legacy JSON with rain/traffic fields that should be ignored
    let json = """
    {
      "isNight": true,
      "isRaining": true,
      "isHeavyTraffic": false
    }
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(TripConditions.self, from: data)

    XCTAssertTrue(decoded.isNight)
  }

  // MARK: - TripPoint Tests

  func testTripPointCoordinate() {
    let point = TripPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      timestamp: Date(),
      speedMetersPerSecond: 5.0,
      horizontalAccuracy: 10.0
    )

    XCTAssertEqual(point.coordinate.latitude, 12.9716, accuracy: 0.0001)
    XCTAssertEqual(point.coordinate.longitude, 77.5946, accuracy: 0.0001)
  }

  func testTripPointEncodeDecode() throws {
    let point = TripPoint(
      id: UUID(),
      latitude: 12.9716,
      longitude: 77.5946,
      timestamp: Date(timeIntervalSince1970: 1000000),
      speedMetersPerSecond: 5.5,
      horizontalAccuracy: 10.0
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(point)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TripPoint.self, from: data)

    XCTAssertEqual(decoded.id, point.id)
    XCTAssertEqual(decoded.latitude, point.latitude)
    XCTAssertEqual(decoded.longitude, point.longitude)
    XCTAssertEqual(decoded.speedMetersPerSecond, point.speedMetersPerSecond)
    XCTAssertEqual(decoded.horizontalAccuracy, point.horizontalAccuracy)
  }

  // MARK: - MeterSettings Codable Tests

  func testMeterSettingsEncodeDecode() throws {
    let settings = MeterSettings.bengaluruDefault

    let encoder = JSONEncoder()
    let data = try encoder.encode(settings)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(MeterSettings.self, from: data)

    XCTAssertEqual(decoded, settings)
  }

  func testMeterSettingsDecodingWithMissingOptionalFields() throws {
    // Minimal JSON without optional fields
    let json = """
    {
      "baseFare": 40,
      "perKmRate": 20,
      "perMinuteRate": 0,
      "minFare": 40,
      "nightMultiplier": 1.5
    }
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(MeterSettings.self, from: data)

    // Should use defaults for missing fields
    XCTAssertEqual(decoded.includedKm, MeterSettings.bengaluruDefault.includedKm)
    XCTAssertEqual(decoded.nightStartHour, MeterSettings.bengaluruDefault.nightStartHour)
    XCTAssertEqual(decoded.nightEndHour, MeterSettings.bengaluruDefault.nightEndHour)
    XCTAssertEqual(decoded.freeWaitMinutes, MeterSettings.bengaluruDefault.freeWaitMinutes)
    XCTAssertEqual(decoded.waitIntervalMinutes, MeterSettings.bengaluruDefault.waitIntervalMinutes)
    XCTAssertEqual(decoded.waitIntervalCharge, MeterSettings.bengaluruDefault.waitIntervalCharge)
  }

  // MARK: - RateSnapshot Tests

  func testRateSnapshotFromSettings() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(settings: settings)

    XCTAssertNil(snapshot.cityId)
    XCTAssertNil(snapshot.cityName)
    XCTAssertEqual(snapshot.baseFare, settings.baseFare)
    XCTAssertEqual(snapshot.perKmRate, settings.perKmRate)
    XCTAssertEqual(snapshot.includedKm, settings.includedKm)
    XCTAssertEqual(snapshot.minFare, settings.minFare)
    XCTAssertEqual(snapshot.nightMultiplier, settings.nightMultiplier)
    XCTAssertEqual(snapshot.nightStartHour, settings.nightStartHour)
    XCTAssertEqual(snapshot.nightEndHour, settings.nightEndHour)
    XCTAssertEqual(snapshot.freeWaitMinutes, settings.freeWaitMinutes)
    XCTAssertEqual(snapshot.waitIntervalMinutes, settings.waitIntervalMinutes)
    XCTAssertEqual(snapshot.waitIntervalCharge, settings.waitIntervalCharge)
  }

  func testRateSnapshotWithCityInfo() {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(settings: settings, cityId: "bengaluru", cityName: "Bengaluru")

    XCTAssertEqual(snapshot.cityId, "bengaluru")
    XCTAssertEqual(snapshot.cityName, "Bengaluru")
  }

  func testRateSnapshotEncodeDecode() throws {
    let settings = MeterSettings.bengaluruDefault
    let snapshot = RateSnapshot(settings: settings, cityId: "mysuru", cityName: "Mysuru")

    let encoder = JSONEncoder()
    let data = try encoder.encode(snapshot)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(RateSnapshot.self, from: data)

    XCTAssertEqual(decoded, snapshot)
  }

  // MARK: - Trip Tests

  func testTripEncodeDecode() throws {
    let trip = Trip(
      id: UUID(),
      startDate: Date(timeIntervalSince1970: 1000000),
      endDate: Date(timeIntervalSince1970: 1001800),
      distanceMeters: 5000,
      duration: 1800,
      fare: 126,
      points: [
        TripPoint(latitude: 12.97, longitude: 77.59, timestamp: Date(timeIntervalSince1970: 1000000), speedMetersPerSecond: 0, horizontalAccuracy: 10),
        TripPoint(latitude: 12.98, longitude: 77.60, timestamp: Date(timeIntervalSince1970: 1001800), speedMetersPerSecond: 5, horizontalAccuracy: 10)
      ],
      conditions: TripConditions(isNight: false),
      rateSnapshot: RateSnapshot(settings: .bengaluruDefault, cityId: "bengaluru", cityName: "Bengaluru"),
      multiplier: 1.0,
      name: "Test Trip",
      startLocationName: "MG Road",
      waitingDuration: 120
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(trip)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Trip.self, from: data)

    XCTAssertEqual(decoded.id, trip.id)
    XCTAssertEqual(decoded.distanceMeters, trip.distanceMeters)
    XCTAssertEqual(decoded.fare, trip.fare)
    XCTAssertEqual(decoded.points.count, trip.points.count)
    XCTAssertEqual(decoded.name, trip.name)
    XCTAssertEqual(decoded.startLocationName, trip.startLocationName)
    XCTAssertEqual(decoded.waitingDuration, trip.waitingDuration)
  }

  func testTripDecodingWithMissingOptionalFields() throws {
    // JSON without optional name, startLocationName, waitingDuration
    let json = """
    {
      "id": "12345678-1234-1234-1234-123456789012",
      "startDate": 1000000,
      "endDate": 1001800,
      "distanceMeters": 5000,
      "duration": 1800,
      "fare": 126,
      "points": [],
      "conditions": {"isNight": false},
      "rateSnapshot": {
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
      },
      "multiplier": 1.0
    }
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(Trip.self, from: data)

    XCTAssertNil(decoded.name)
    XCTAssertNil(decoded.startLocationName)
    XCTAssertEqual(decoded.waitingDuration, 0) // Default when missing
  }

  func testTripWithEmptyPoints() throws {
    let trip = Trip(
      id: UUID(),
      startDate: Date(),
      endDate: Date(),
      distanceMeters: 0,
      duration: 0,
      fare: 36, // Minimum fare
      points: [],
      conditions: .clear,
      rateSnapshot: RateSnapshot(settings: .bengaluruDefault),
      multiplier: 1.0
    )

    XCTAssertTrue(trip.points.isEmpty)
    XCTAssertEqual(trip.fare, 36) // Minimum fare applies
  }
}
