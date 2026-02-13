import Foundation
import XCTest
@testable import NammaMeter

final class SurchargeTests: XCTestCase {
  private func date(year: Int = 2026, month: Int = 2, day: Int = 3, hour: Int, weekday: Int? = nil) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    let base = Calendar.autoupdatingCurrent.date(from: components)!
    if let weekday {
      // Adjust to the target weekday (1=Sun..7=Sat)
      let current = Calendar.autoupdatingCurrent.component(.weekday, from: base)
      let diff = weekday - current
      return Calendar.autoupdatingCurrent.date(byAdding: .day, value: diff, to: base)!
    }
    return base
  }

  // MARK: - SurchargeCondition

  func testAlwaysConditionMatches() {
    let condition = SurchargeCondition.always
    XCTAssertTrue(condition.matches(at: date(hour: 10)))
    XCTAssertTrue(condition.matches(at: date(hour: 23)))
    XCTAssertTrue(condition.isAlways)
  }

  func testTimeOfDayConditionSameDay() {
    let condition = SurchargeCondition.timeOfDay(start: 16, end: 20)
    XCTAssertTrue(condition.matches(at: date(hour: 16)))
    XCTAssertTrue(condition.matches(at: date(hour: 19)))
    XCTAssertFalse(condition.matches(at: date(hour: 20)))
    XCTAssertFalse(condition.matches(at: date(hour: 15)))
    XCTAssertFalse(condition.matches(at: date(hour: 10)))
  }

  func testTimeOfDayConditionWrapAround() {
    let condition = SurchargeCondition.timeOfDay(start: 22, end: 5)
    XCTAssertTrue(condition.matches(at: date(hour: 22)))
    XCTAssertTrue(condition.matches(at: date(hour: 23)))
    XCTAssertTrue(condition.matches(at: date(hour: 0)))
    XCTAssertTrue(condition.matches(at: date(hour: 4)))
    XCTAssertFalse(condition.matches(at: date(hour: 5)))
    XCTAssertFalse(condition.matches(at: date(hour: 21)))
  }

  func testTimeOfDayEqualStartEndMatchesAll() {
    let condition = SurchargeCondition(startHour: 10, endHour: 10, daysOfWeek: nil)
    XCTAssertTrue(condition.matches(at: date(hour: 10)))
    XCTAssertTrue(condition.matches(at: date(hour: 15)))
    XCTAssertTrue(condition.matches(at: date(hour: 3)))
  }

  func testDaysOfWeekCondition() {
    // Monday=2, Tuesday=3, Wednesday=4, Thursday=5, Friday=6
    let condition = SurchargeCondition(startHour: nil, endHour: nil, daysOfWeek: [2, 3, 4, 5, 6])
    XCTAssertTrue(condition.matches(at: date(hour: 10, weekday: 2)))  // Monday
    XCTAssertTrue(condition.matches(at: date(hour: 10, weekday: 6)))  // Friday
    XCTAssertFalse(condition.matches(at: date(hour: 10, weekday: 1))) // Sunday
    XCTAssertFalse(condition.matches(at: date(hour: 10, weekday: 7))) // Saturday
  }

  func testCompoundConditionAND() {
    // Rush hour: 16-20 on weekdays only
    let condition = SurchargeCondition.weekdays(start: 16, end: 20)
    // Wednesday at 17:00
    XCTAssertTrue(condition.matches(at: date(hour: 17, weekday: 4)))
    // Wednesday at 10:00 (wrong time)
    XCTAssertFalse(condition.matches(at: date(hour: 10, weekday: 4)))
    // Sunday at 17:00 (wrong day)
    XCTAssertFalse(condition.matches(at: date(hour: 17, weekday: 1)))
  }

  // MARK: - FareSurcharge

  func testSurchargeActiveWithORConditions() {
    let surcharge = FareSurcharge(
      id: "night",
      name: "Night",
      type: .percentageOfFare(0.50),
      conditions: [
        .timeOfDay(start: 22, end: 5),
        .timeOfDay(start: 0, end: 6),
      ]
    )
    XCTAssertTrue(surcharge.isActive(at: date(hour: 23)))
    XCTAssertTrue(surcharge.isActive(at: date(hour: 3)))
    XCTAssertFalse(surcharge.isActive(at: date(hour: 12)))
  }

  func testSurchargeAlwaysActive() {
    let surcharge = FareSurcharge(
      id: "mta",
      name: "MTA Tax",
      type: .fixedAmount(0.50),
      conditions: [.always]
    )
    XCTAssertTrue(surcharge.isActive(at: date(hour: 10)))
    XCTAssertTrue(surcharge.isActive(at: date(hour: 23)))
  }

  func testSurchargeEmptyConditionsAlwaysActive() {
    let surcharge = FareSurcharge(
      id: "fee",
      name: "Fee",
      type: .fixedAmount(1.00),
      conditions: []
    )
    XCTAssertTrue(surcharge.isActive(at: date(hour: 12)))
  }

  // MARK: - Codable Round-Trip

  func testSurchargeConditionCodable() throws {
    let condition = SurchargeCondition.weekdays(start: 16, end: 20)
    let data = try JSONEncoder().encode(condition)
    let decoded = try JSONDecoder().decode(SurchargeCondition.self, from: data)
    XCTAssertEqual(condition, decoded)
  }

  func testSurchargeTypeCodable() throws {
    let percentage = SurchargeType.percentageOfFare(0.25)
    let fixed = SurchargeType.fixedAmount(2.50)

    let data1 = try JSONEncoder().encode(percentage)
    let decoded1 = try JSONDecoder().decode(SurchargeType.self, from: data1)
    XCTAssertEqual(percentage, decoded1)

    let data2 = try JSONEncoder().encode(fixed)
    let decoded2 = try JSONDecoder().decode(SurchargeType.self, from: data2)
    XCTAssertEqual(fixed, decoded2)
  }

  func testFareSurchargeCodable() throws {
    let surcharge = FareSurcharge(
      id: "nyc-night",
      name: "Night",
      type: .fixedAmount(1.00),
      conditions: [.timeOfDay(start: 20, end: 6)]
    )
    let data = try JSONEncoder().encode(surcharge)
    let decoded = try JSONDecoder().decode(FareSurcharge.self, from: data)
    XCTAssertEqual(surcharge, decoded)
  }
}
