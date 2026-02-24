import XCTest
@testable import NammaMeter

final class NeoLCDLayoutLogicTests: XCTestCase {
  func testCompassDirectionFormatterReturnsCardinalDirection() {
    let now = Date()
    let points = [
      TripPoint(latitude: 12.9716, longitude: 77.5946, timestamp: now, speedMetersPerSecond: 4, horizontalAccuracy: 5),
      TripPoint(latitude: 12.9726, longitude: 77.5956, timestamp: now.addingTimeInterval(1), speedMetersPerSecond: 4, horizontalAccuracy: 5)
    ]

    XCTAssertEqual(CompassDirectionFormatter.direction(for: points), "NE")
  }

  func testCompassDirectionFormatterReturnsPlaceholderWhenNoMovement() {
    let now = Date()
    let points = [
      TripPoint(latitude: 12.9716, longitude: 77.5946, timestamp: now, speedMetersPerSecond: 0, horizontalAccuracy: 5),
      TripPoint(latitude: 12.9716, longitude: 77.5946, timestamp: now.addingTimeInterval(1), speedMetersPerSecond: 0, horizontalAccuracy: 5)
    ]

    XCTAssertEqual(CompassDirectionFormatter.direction(for: points), "--")
  }

  func testCompassDirectionFormatterFallsBackToEarlierMovingSegment() {
    let now = Date()
    let points = [
      TripPoint(latitude: 12.9716, longitude: 77.5946, timestamp: now, speedMetersPerSecond: 3, horizontalAccuracy: 5),
      TripPoint(latitude: 12.9716, longitude: 77.6046, timestamp: now.addingTimeInterval(1), speedMetersPerSecond: 3, horizontalAccuracy: 5),
      TripPoint(latitude: 12.9716, longitude: 77.6046, timestamp: now.addingTimeInterval(2), speedMetersPerSecond: 0, horizontalAccuracy: 5)
    ]

    XCTAssertEqual(CompassDirectionFormatter.direction(for: points), "E")
  }

  func testCompassDirectionFormatterReturnsSouthDirection() {
    let now = Date()
    let points = [
      TripPoint(latitude: 12.9716, longitude: 77.5946, timestamp: now, speedMetersPerSecond: 4, horizontalAccuracy: 5),
      TripPoint(latitude: 12.9616, longitude: 77.5946, timestamp: now.addingTimeInterval(1), speedMetersPerSecond: 4, horizontalAccuracy: 5)
    ]

    XCTAssertEqual(CompassDirectionFormatter.direction(for: points), "S")
  }

  func testFareRuleEvaluatorHighlightsNightRuleWhenActive() {
    let profile = FareCatalog.entries.first(where: { $0.profile.cityId == "bengaluru" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw })!.profile

    var components = DateComponents()
    components.year = 2026; components.month = 2; components.day = 16; components.hour = 23
    let nightDate = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.2,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: nightDate,
      currentFare: 54
    )
    let results = FareRuleEvaluator.evaluate(profile: profile, context: context)
    let nightRule = results.first(where: { $0.rule.kind == .surcharge })
    XCTAssertNotNil(nightRule)
    XCTAssertTrue(nightRule!.isActive, "Night surcharge should be active at 23:00")
  }

  func testFareRuleEvaluatorNightAndWaitingInactiveAtForHire() {
    let profile = FareCatalog.entries.first(where: { $0.profile.cityId == "bengaluru" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw })!.profile

    var components = DateComponents()
    components.year = 2026; components.month = 2; components.day = 16; components.hour = 14
    let dayDate = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .forHire,
      distanceKm: 0,
      elapsedTime: 0,
      waitingTime: 0,
      currentSpeedKph: nil,
      tripDate: dayDate,
      currentFare: 0
    )
    let results = FareRuleEvaluator.evaluate(profile: profile, context: context)
    let nightRule = results.first(where: { $0.rule.kind == .surcharge })
    XCTAssertNotNil(nightRule)
    XCTAssertFalse(nightRule!.isActive, "Night surcharge should be inactive at 14:00")

    let waitingRule = results.first(where: { $0.rule.kind == .waitingCharge })
    XCTAssertNotNil(waitingRule)
    XCTAssertFalse(waitingRule!.isActive, "Waiting should be inactive at forHire")
  }

  func testTopBarStatusIncludesCityVehicleContextWhenPresent() {
    let text = NeoLCDHeaderFormatter.topBarStatus(
      statusText: "HIRED",
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    XCTAssertEqual(text, "HIRED · Bengaluru · Auto Rickshaw")
  }

  func testTopBarStatusFallsBackWhenContextEmpty() {
    let text = NeoLCDHeaderFormatter.topBarStatus(statusText: "WAITING", cityVehicleLabel: "  ")
    XCTAssertEqual(text, "WAITING")
  }

  func testFareRuleEvaluatorTimeChargeActiveWhenComplete() {
    let snapshot = RateSnapshot(
      settings: MeterSettings(
        baseFare: 30, perKmRate: 10, perMinuteRate: 2,
        includedKm: 2.0, minFare: 30,
        nightMultiplier: 1.0, nightStartHour: 22, nightEndHour: 5,
        freeWaitMinutes: 5, waitIntervalMinutes: 15, waitIntervalCharge: 5,
        keepScreenAwakeDuringTrip: false
      )
    )

    var components = DateComponents()
    components.year = 2026; components.month = 2; components.day = 16; components.hour = 14
    let dayDate = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .complete,
      distanceKm: 5.0,
      elapsedTime: 900,
      waitingTime: 120,
      currentSpeedKph: 0,
      tripDate: dayDate,
      currentFare: 78
    )
    let results = FareRuleEvaluator.evaluate(snapshot: snapshot, context: context)
    let timeRule = results.first(where: { $0.rule.kind == .timeCharge })
    XCTAssertNotNil(timeRule, "Profile with perMinuteRate > 0 should produce a time charge rule")
    if let timeRule {
      XCTAssertTrue(timeRule.isActive, "Time charge should be active when trip is complete")
      XCTAssertGreaterThan(timeRule.amount, 0)
    }
  }

  func testFareRuleEvaluatorTimeChargeInactiveWhenForHire() {
    let snapshot = RateSnapshot(
      settings: MeterSettings(
        baseFare: 30, perKmRate: 10, perMinuteRate: 2,
        includedKm: 2.0, minFare: 30,
        nightMultiplier: 1.0, nightStartHour: 22, nightEndHour: 5,
        freeWaitMinutes: 5, waitIntervalMinutes: 15, waitIntervalCharge: 5,
        keepScreenAwakeDuringTrip: false
      )
    )

    var components = DateComponents()
    components.year = 2026; components.month = 2; components.day = 16; components.hour = 14
    let dayDate = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .forHire,
      distanceKm: 0,
      elapsedTime: 0,
      waitingTime: 0,
      currentSpeedKph: nil,
      tripDate: dayDate,
      currentFare: 0
    )
    let results = FareRuleEvaluator.evaluate(snapshot: snapshot, context: context)
    let timeRule = results.first(where: { $0.rule.kind == .timeCharge })
    XCTAssertNotNil(timeRule)
    if let timeRule {
      XCTAssertFalse(timeRule.isActive, "Time charge should be inactive when for hire")
    }
  }

  func testFareBreakdownShowsActiveRulesWhenComplete() {
    let profile = FareCatalog.entries.first(where: { $0.profile.cityId == "bengaluru" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw })!.profile

    var components = DateComponents()
    components.year = 2026; components.month = 2; components.day = 16; components.hour = 14
    let dayDate = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .complete,
      distanceKm: 5.0,
      elapsedTime: 900,
      waitingTime: 600,
      currentSpeedKph: 0,
      tripDate: dayDate,
      currentFare: 90
    )
    let results = FareRuleEvaluator.evaluate(profile: profile, context: context)

    let baseFare = results.first(where: { $0.rule.kind == .baseFare })
    XCTAssertNotNil(baseFare)
    XCTAssertTrue(baseFare!.isActive, "Base fare should always be active")
    XCTAssertEqual(baseFare!.amount, 36, accuracy: 0.01)

    let distanceCharge = results.first(where: { $0.rule.kind == .distanceCharge })
    XCTAssertNotNil(distanceCharge)
    XCTAssertTrue(distanceCharge!.isActive, "Distance charge should be active for 5km trip (included=2km)")
    XCTAssertEqual(distanceCharge!.amount, 54, accuracy: 0.01) // (5-2)*18
  }

  func testFareCardHeaderPrefersCityVehicleLabel() {
    let header = NeoLCDHeaderFormatter.fareCardHeader(
      cityName: "Bengaluru",
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    XCTAssertEqual(header, "Bengaluru · Auto Rickshaw")
  }

  func testFareCardHeaderFallsBackToCityNameWhenContextEmpty() {
    let header = NeoLCDHeaderFormatter.fareCardHeader(
      cityName: "Bengaluru",
      cityVehicleLabel: "   "
    )
    XCTAssertEqual(header, "Bengaluru")
  }
}
