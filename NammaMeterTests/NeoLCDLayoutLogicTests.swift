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

  func testFareRuleBuilderIncludesNightRuleOnlyWhenNightIsActive() {
    let rules = NeoLCDFareRuleBuilder.activeRules(
      settings: .bengaluruDefault,
      tripState: .inProgress,
      fare: 54,
      distanceKm: 3.2,
      isNight: true
    )

    XCTAssertTrue(rules.contains { $0.contains("Night surcharge") })
  }

  func testFareRuleBuilderOmitsNightAndWaitingRulesWhenInactive() {
    let rules = NeoLCDFareRuleBuilder.activeRules(
      settings: .bengaluruDefault,
      tripState: .forHire,
      fare: 36,
      distanceKm: 0,
      isNight: false
    )

    XCTAssertFalse(rules.contains { $0.localizedCaseInsensitiveContains("night") })
    XCTAssertFalse(rules.contains { $0.localizedCaseInsensitiveContains("waiting") })
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

  func testFareCardHeaderPrefersCityVehicleLabel() {
    let header = NeoLCDHeaderFormatter.fareCardHeader(
      cityName: "Bengaluru",
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    XCTAssertEqual(header, "Bengaluru · Auto Rickshaw")
  }
}
