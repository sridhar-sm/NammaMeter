import Foundation
import XCTest
@testable import NammaMeter

final class FareCalculationStrategyTests: XCTestCase {

  // MARK: - SurchargeCalculator

  func testEvaluateActiveSurcharges() {
    let surcharges = [
      FareSurcharge(
        id: "night", name: "Night",
        type: .percentageOfFare(0.50),
        conditions: [.timeOfDay(start: 22, end: 5)]
      ),
    ]

    // 23:00 — night surcharge active
    let nightDate = makeDate(hour: 23)
    let result = SurchargeCalculator.evaluate(surcharges, subtotal: 100, at: nightDate)
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].amount, 50.0, accuracy: 0.01)
    XCTAssertEqual(result[0].name, "Night")
  }

  func testEvaluateInactiveSurcharges() {
    let surcharges = [
      FareSurcharge(
        id: "night", name: "Night",
        type: .percentageOfFare(0.50),
        conditions: [.timeOfDay(start: 22, end: 5)]
      ),
    ]

    // 12:00 — night surcharge inactive
    let dayDate = makeDate(hour: 12)
    let result = SurchargeCalculator.evaluate(surcharges, subtotal: 100, at: dayDate)
    XCTAssertTrue(result.isEmpty)
  }

  func testEvaluateFixedAmountSurcharge() {
    let surcharges = [
      FareSurcharge(
        id: "mta", name: "MTA Tax",
        type: .fixedAmount(0.50),
        conditions: [.always]
      ),
    ]

    let result = SurchargeCalculator.evaluate(surcharges, subtotal: 200, at: Date())
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].amount, 0.50, accuracy: 0.01)
  }

  func testEvaluateMultipleSurcharges() {
    let surcharges = [
      FareSurcharge(
        id: "mta", name: "MTA Tax",
        type: .fixedAmount(0.50),
        conditions: [.always]
      ),
      FareSurcharge(
        id: "improvement", name: "Improvement",
        type: .fixedAmount(1.00),
        conditions: [.always]
      ),
      FareSurcharge(
        id: "night", name: "Night",
        type: .fixedAmount(1.00),
        conditions: [.timeOfDay(start: 20, end: 6)]
      ),
    ]

    // At 21:00 — all three active
    let nightDate = makeDate(hour: 21)
    let result = SurchargeCalculator.evaluate(surcharges, subtotal: 10, at: nightDate)
    XCTAssertEqual(result.count, 3)
    let total = result.reduce(0) { $0 + $1.amount }
    XCTAssertEqual(total, 2.50, accuracy: 0.01)
  }

  func testEvaluateEmptySurcharges() {
    let result = SurchargeCalculator.evaluate([], subtotal: 100, at: Date())
    XCTAssertTrue(result.isEmpty)
  }

  // MARK: - FareBreakdown: Bengaluru day matches legacy

  func testBengaluruDayBreakdownMatchesLegacy() {
    let settings = MeterSettings.bengaluruDefault
    let calculator = FareCalculator(settings: settings)
    let distanceKm = 5.0
    let elapsed: TimeInterval = 600
    let waiting: TimeInterval = 0

    let legacyFare = calculator.calculateFare(
      distanceKm: distanceKm, elapsedTime: elapsed,
      waitingTime: waiting, isNight: false
    )

    let breakdown = calculator.calculateFare(
      distanceKm: distanceKm, elapsedTime: elapsed,
      waitingTime: waiting, currentSpeedKph: nil,
      surcharges: nil, tripDate: makeDate(hour: 12), isNight: false
    )

    XCTAssertEqual(breakdown.total, legacyFare, accuracy: 0.01)
  }

  // MARK: - FareBreakdown: Bengaluru night via surcharges matches 1.5x

  func testBengaluruNightSurchargeMatchesLegacyMultiplier() {
    let settings = MeterSettings.bengaluruDefault
    let calculator = FareCalculator(settings: settings)
    let distanceKm = 5.0
    let elapsed: TimeInterval = 600
    let waiting: TimeInterval = 0

    // Legacy night via multiplier
    let legacyNight = calculator.calculateFare(
      distanceKm: distanceKm, elapsedTime: elapsed,
      waitingTime: waiting, isNight: true
    )

    // New path via surcharges
    let surcharges = [
      FareSurcharge(
        id: "night", name: "Night",
        type: .percentageOfFare(0.50),
        conditions: [.timeOfDay(start: 22, end: 5)]
      ),
    ]
    let nightDate = makeDate(hour: 23)
    let breakdown = calculator.calculateFare(
      distanceKm: distanceKm, elapsedTime: elapsed,
      waitingTime: waiting, currentSpeedKph: nil,
      surcharges: surcharges, tripDate: nightDate, isNight: true
    )

    XCTAssertEqual(breakdown.total, legacyNight, accuracy: 0.01)
  }

  func testNilSurchargesFallsBackToLegacy() {
    let settings = MeterSettings.bengaluruDefault
    let calculator = FareCalculator(settings: settings)

    let breakdown = calculator.calculateFare(
      distanceKm: 5.0, elapsedTime: 600,
      waitingTime: 0, currentSpeedKph: nil,
      surcharges: nil, tripDate: makeDate(hour: 23), isNight: true
    )

    // Legacy path: subtotal * 1.5
    let baseFare = settings.baseFare
    let distanceFare = (5.0 - settings.includedKm) * settings.perKmRate
    let subtotal = baseFare + distanceFare
    let expected = max(settings.minFare, subtotal * 1.5)
    XCTAssertEqual(breakdown.total, expected, accuracy: 0.01)
  }

  // MARK: - Speed-based calculation

  func testSpeedBasedDistanceDominates() {
    // NYC-like: perMinuteWhenSlow=0.70, threshold=19kph
    let settings = MeterSettings(
      baseFare: 3.00, perKmRate: 2.18, perMinuteRate: 0,
      includedKm: 0, minFare: 3.00, nightMultiplier: 1.0,
      nightStartHour: 0, nightEndHour: 0,
      freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0,
      keepScreenAwakeDuringTrip: false
    )
    let calculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: 0.70,
      slowSpeedThresholdKph: 19.0
    )

    // 10km in 10 minutes (fast trip, distance dominates)
    let breakdown = calculator.calculateFare(
      distanceKm: 10.0, elapsedTime: 600,
      waitingTime: 0, currentSpeedKph: 60,
      surcharges: [], tripDate: Date(), isNight: false
    )

    let expectedDistance = 10.0 * 2.18
    let expectedTime = 10.0 * 0.70
    // distance > time, so subtotal = baseFare + distanceFare
    XCTAssertGreaterThan(expectedDistance, expectedTime)
    XCTAssertEqual(breakdown.subtotal, 3.00 + expectedDistance, accuracy: 0.01)
    XCTAssertEqual(breakdown.waitingFare, 0)
  }

  func testSpeedBasedTimeDominates() {
    let settings = MeterSettings(
      baseFare: 3.00, perKmRate: 2.18, perMinuteRate: 0,
      includedKm: 0, minFare: 3.00, nightMultiplier: 1.0,
      nightStartHour: 0, nightEndHour: 0,
      freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0,
      keepScreenAwakeDuringTrip: false
    )
    let calculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: 0.70,
      slowSpeedThresholdKph: 19.0
    )

    // 1km in 30 minutes (slow/stuck in traffic, time dominates)
    let breakdown = calculator.calculateFare(
      distanceKm: 1.0, elapsedTime: 1800,
      waitingTime: 0, currentSpeedKph: 2,
      surcharges: [], tripDate: Date(), isNight: false
    )

    let expectedDistance = 1.0 * 2.18
    let expectedTime = 30.0 * 0.70
    // time > distance
    XCTAssertGreaterThan(expectedTime, expectedDistance)
    XCTAssertEqual(breakdown.subtotal, 3.00 + expectedTime, accuracy: 0.01)
  }

  func testSpeedBasedNilSpeedUsesMaxModel() {
    // WhatIf scenario: nil speed → still uses max(distance, time)
    let settings = MeterSettings(
      baseFare: 3.00, perKmRate: 2.18, perMinuteRate: 0,
      includedKm: 0, minFare: 3.00, nightMultiplier: 1.0,
      nightStartHour: 0, nightEndHour: 0,
      freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0,
      keepScreenAwakeDuringTrip: false
    )
    let calculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: 0.70,
      slowSpeedThresholdKph: 19.0
    )

    let breakdown = calculator.calculateFare(
      distanceKm: 5.0, elapsedTime: 900,
      waitingTime: 0, currentSpeedKph: nil,
      surcharges: [], tripDate: Date(), isNight: false
    )

    let distanceFare = 5.0 * 2.18
    let timeFare = 15.0 * 0.70
    let expected = 3.00 + max(distanceFare, timeFare)
    XCTAssertEqual(breakdown.subtotal, expected, accuracy: 0.01)
    XCTAssertEqual(breakdown.waitingFare, 0)
  }

  func testSpeedBasedNoWaitingCharge() {
    let settings = MeterSettings(
      baseFare: 3.00, perKmRate: 2.18, perMinuteRate: 0,
      includedKm: 0, minFare: 3.00, nightMultiplier: 1.0,
      nightStartHour: 0, nightEndHour: 0,
      freeWaitMinutes: 5, waitIntervalMinutes: 15, waitIntervalCharge: 10,
      keepScreenAwakeDuringTrip: false
    )
    let calculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: 0.70,
      slowSpeedThresholdKph: 19.0
    )

    // Even with waiting time, speed-based model ignores it
    let breakdown = calculator.calculateFare(
      distanceKm: 5.0, elapsedTime: 900,
      waitingTime: 600, currentSpeedKph: nil,
      surcharges: [], tripDate: Date(), isNight: false
    )

    XCTAssertEqual(breakdown.waitingFare, 0)
  }

  // MARK: - Backward compat: old 4-param method

  func testLegacy4ParamMethodStillWorks() {
    let settings = MeterSettings.bengaluruDefault
    let calculator = FareCalculator(settings: settings)

    let fare = calculator.calculateFare(
      distanceKm: 5.0, elapsedTime: 600,
      waitingTime: 0, isNight: false
    )

    let baseFare = settings.baseFare
    let distanceFare = (5.0 - settings.includedKm) * settings.perKmRate
    let expected = max(settings.minFare, baseFare + distanceFare)
    XCTAssertEqual(fare, expected, accuracy: 0.01)
  }

  // MARK: - FareBreakdown components

  func testBreakdownComponentsAddUp() {
    let settings = MeterSettings.bengaluruDefault
    let calculator = FareCalculator(settings: settings)

    let breakdown = calculator.calculateFare(
      distanceKm: 5.0, elapsedTime: 600,
      waitingTime: 1200, currentSpeedKph: nil,
      surcharges: nil, tripDate: makeDate(hour: 12), isNight: false
    )

    let computedSubtotal = breakdown.baseFare + breakdown.distanceFare + breakdown.timeFare + breakdown.waitingFare
    XCTAssertEqual(breakdown.subtotal, computedSubtotal, accuracy: 0.01)
  }

  // MARK: - Helpers

  private func makeDate(hour: Int) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 10
    components.hour = hour
    return Calendar.autoupdatingCurrent.date(from: components)!
  }
}
