import Foundation
import XCTest
@testable import NammaMeter

final class BackwardCompatibilityTests: XCTestCase {
  func testDecodeMeterSettingsDefaultsForWaitingFields() throws {
    let json = """
    {
      "baseFare": 30,
      "perKmRate": 15,
      "perMinuteRate": 1.5,
      "minFare": 30,
      "nightMultiplier": 1.25
    }
    """
    let data = Data(json.utf8)
    let decoded = try JSONDecoder().decode(MeterSettings.self, from: data)
    let defaults = MeterSettings.bengaluruDefault

    XCTAssertEqual(decoded.freeWaitMinutes, defaults.freeWaitMinutes)
    XCTAssertEqual(decoded.waitIntervalMinutes, defaults.waitIntervalMinutes)
    XCTAssertEqual(decoded.waitIntervalCharge, defaults.waitIntervalCharge)
  }

  func testDecodeRateSnapshotDefaultsForWaitingFields() throws {
    let json = """
    {
      "baseFare": 30,
      "perKmRate": 15,
      "perMinuteRate": 1.5,
      "minFare": 30,
      "nightMultiplier": 1.25
    }
    """
    let data = Data(json.utf8)
    let decoded = try JSONDecoder().decode(RateSnapshot.self, from: data)
    let defaults = MeterSettings.bengaluruDefault

    XCTAssertEqual(decoded.freeWaitMinutes, defaults.freeWaitMinutes)
    XCTAssertEqual(decoded.waitIntervalMinutes, defaults.waitIntervalMinutes)
    XCTAssertEqual(decoded.waitIntervalCharge, defaults.waitIntervalCharge)
  }

  func testDecodeTripRateSnapshotDefaultsForWaitingFields() throws {
    let json = """
    {
      "id": "E13E6F3C-6C7E-4F51-9E14-6B7A2F5DABCD",
      "startDate": 0,
      "endDate": 60,
      "distanceMeters": 1000,
      "duration": 60,
      "fare": 50,
      "points": [],
      "conditions": { "isNight": false },
      "rateSnapshot": {
        "baseFare": 30,
        "perKmRate": 15,
        "perMinuteRate": 1.5,
        "minFare": 30,
        "nightMultiplier": 1.25
      },
      "multiplier": 1,
      "waitingDuration": 0
    }
    """
    let data = Data(json.utf8)
    let decoded = try JSONDecoder().decode(Trip.self, from: data)
    let defaults = MeterSettings.bengaluruDefault

    XCTAssertEqual(decoded.rateSnapshot.freeWaitMinutes, defaults.freeWaitMinutes)
    XCTAssertEqual(decoded.rateSnapshot.waitIntervalMinutes, defaults.waitIntervalMinutes)
    XCTAssertEqual(decoded.rateSnapshot.waitIntervalCharge, defaults.waitIntervalCharge)
  }
}
