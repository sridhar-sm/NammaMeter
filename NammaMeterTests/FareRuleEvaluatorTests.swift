import XCTest
@testable import NammaMeter

final class FareRuleEvaluatorTests: XCTestCase {

  // MARK: - Helpers

  private var bengaluruProfile: CityFareProfile {
    FareCatalog.entries.first(where: { $0.profile.cityId == "bengaluru" && $0.profile.vehicleType == VehicleTypeCatalog.autoRickshaw })!.profile
  }

  private var nycProfile: CityFareProfile {
    FareCatalog.entries.first(where: { $0.profile.cityId == "nyc" })!.profile
  }

  private var seattleProfile: CityFareProfile {
    FareCatalog.entries.first(where: { $0.profile.cityId == "seattle" })!.profile
  }

  private func dayDate(hour: Int) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 16
    components.hour = hour
    components.minute = 0
    components.second = 0
    return Calendar.current.date(from: components)!
  }

  // MARK: - Rule Generation

  func testBengaluruAutoRuleGeneration() {
    let rules = FareRuleEvaluator.allRules(from: bengaluruProfile)
    let kinds = rules.map(\.kind)

    XCTAssertTrue(kinds.contains(.baseFare))
    XCTAssertTrue(kinds.contains(.distanceCharge))
    XCTAssertTrue(kinds.contains(.waitingCharge))
    XCTAssertTrue(kinds.contains(.minimumFare))
    XCTAssertTrue(kinds.contains(.surcharge), "Should have night surcharge")
    XCTAssertFalse(kinds.contains(.timeCharge), "Bengaluru has perMinuteRate=0")
    XCTAssertFalse(kinds.contains(.speedBasedCharge), "Bengaluru has no speed model")
  }

  func testNYCYellowTaxiRuleGeneration() {
    let rules = FareRuleEvaluator.allRules(from: nycProfile)
    let kinds = rules.map(\.kind)
    let ids = rules.map(\.id)

    XCTAssertTrue(kinds.contains(.baseFare))
    XCTAssertTrue(kinds.contains(.distanceCharge))
    XCTAssertTrue(kinds.contains(.speedBasedCharge))
    XCTAssertTrue(kinds.contains(.minimumFare))
    XCTAssertFalse(kinds.contains(.waitingCharge), "NYC has no waiting charges")
    XCTAssertFalse(kinds.contains(.timeCharge), "NYC uses speed model, not perMinuteRate")

    // Check all 4 surcharges
    XCTAssertTrue(ids.contains("surcharge:nyc-night"))
    XCTAssertTrue(ids.contains("surcharge:nyc-rush"))
    XCTAssertTrue(ids.contains("surcharge:nyc-mta"))
    XCTAssertTrue(ids.contains("surcharge:nyc-improvement"))
  }

  func testSeattleRuleGeneration() {
    let rules = FareRuleEvaluator.allRules(from: seattleProfile)
    let kinds = rules.map(\.kind)

    XCTAssertTrue(kinds.contains(.baseFare))
    XCTAssertTrue(kinds.contains(.distanceCharge))
    XCTAssertTrue(kinds.contains(.waitingCharge))
    XCTAssertTrue(kinds.contains(.minimumFare))
    XCTAssertFalse(kinds.contains(.surcharge), "Seattle has no surcharges")
    XCTAssertFalse(kinds.contains(.speedBasedCharge), "Seattle has no speed model")
  }

  func testRuleDescriptionsIncludeCurrencySymbol() {
    let inrRules = FareRuleEvaluator.allRules(from: bengaluruProfile)
    let baseFareRule = inrRules.first(where: { $0.kind == .baseFare })!
    XCTAssertTrue(baseFareRule.description.contains("₹"), "INR should use ₹ symbol")

    let usdRules = FareRuleEvaluator.allRules(from: nycProfile)
    let nycBase = usdRules.first(where: { $0.kind == .baseFare })!
    XCTAssertTrue(nycBase.description.contains("$"), "USD should use $ symbol")
  }

  // MARK: - Evaluation: ForHire State

  func testForHireStateEvaluation() {
    let context = FareRuleContext(
      tripState: .forHire,
      distanceKm: 0,
      elapsedTime: 0,
      waitingTime: 0,
      currentSpeedKph: nil,
      tripDate: dayDate(hour: 14),
      currentFare: 0
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let baseFare = results.first(where: { $0.rule.kind == .baseFare })!
    XCTAssertTrue(baseFare.isActive, "Base fare always active")
    XCTAssertEqual(baseFare.amount, 36, accuracy: 0.01)

    let distance = results.first(where: { $0.rule.kind == .distanceCharge })!
    XCTAssertFalse(distance.isActive, "No distance at forHire")
    XCTAssertEqual(distance.amount, 0, accuracy: 0.01)

    let waiting = results.first(where: { $0.rule.kind == .waitingCharge })!
    XCTAssertFalse(waiting.isActive, "No waiting at forHire")

    let minFare = results.first(where: { $0.rule.kind == .minimumFare })!
    XCTAssertFalse(minFare.isActive, "Min fare not active at forHire")

    let nightSurcharge = results.first(where: { $0.rule.kind == .surcharge })!
    XCTAssertFalse(nightSurcharge.isActive, "Not night at 14:00")
  }

  // MARK: - Evaluation: InProgress Daytime

  func testInProgressDaytime3km() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.0,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 14),
      currentFare: 54
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let baseFare = results.first(where: { $0.rule.kind == .baseFare })!
    XCTAssertTrue(baseFare.isActive)
    XCTAssertEqual(baseFare.amount, 36, accuracy: 0.01)

    let distance = results.first(where: { $0.rule.kind == .distanceCharge })!
    XCTAssertTrue(distance.isActive, "Beyond 2km included")
    XCTAssertEqual(distance.amount, 18, accuracy: 0.01, "1km × ₹18/km")

    let minFare = results.first(where: { $0.rule.kind == .minimumFare })!
    XCTAssertFalse(minFare.isActive, "Fare 54 > minFare 36")

    let nightSurcharge = results.first(where: { $0.rule.kind == .surcharge })!
    XCTAssertFalse(nightSurcharge.isActive, "Daytime trip")
  }

  // MARK: - Evaluation: Night Surcharge

  func testNightSurchargeActive() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.0,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 23),
      currentFare: 54
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let nightSurcharge = results.first(where: { $0.rule.kind == .surcharge })!
    XCTAssertTrue(nightSurcharge.isActive, "23:00 is within 22:00-05:00 night window")
    XCTAssertGreaterThan(nightSurcharge.amount, 0)
  }

  func testNightSurchargeInactiveDuringDay() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.0,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 10),
      currentFare: 54
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let nightSurcharge = results.first(where: { $0.rule.kind == .surcharge })!
    XCTAssertFalse(nightSurcharge.isActive)
    XCTAssertEqual(nightSurcharge.amount, 0, accuracy: 0.01)
  }

  // MARK: - Evaluation: Waiting Charge

  func testWaitingChargeActivatesAfterFreeMinutes() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 1.0,
      elapsedTime: 1200,
      waitingTime: 20 * 60,   // 20 minutes (> 5 free)
      currentSpeedKph: 0,
      tripDate: dayDate(hour: 14),
      currentFare: 46
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let waiting = results.first(where: { $0.rule.kind == .waitingCharge })!
    XCTAssertTrue(waiting.isActive)
    XCTAssertEqual(waiting.amount, 10, accuracy: 0.01, "15 chargeable min = 1 interval × ₹10")
  }

  func testWaitingChargeInactiveDuringFreeMinutes() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 1.0,
      elapsedTime: 300,
      waitingTime: 3 * 60,   // 3 minutes (< 5 free)
      currentSpeedKph: 0,
      tripDate: dayDate(hour: 14),
      currentFare: 36
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let waiting = results.first(where: { $0.rule.kind == .waitingCharge })!
    XCTAssertFalse(waiting.isActive)
    XCTAssertEqual(waiting.amount, 0, accuracy: 0.01)
  }

  // MARK: - Evaluation: Minimum Fare

  func testMinimumFareActiveWhenBelowThreshold() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 0.5,
      elapsedTime: 60,
      waitingTime: 0,
      currentSpeedKph: 20,
      tripDate: dayDate(hour: 14),
      currentFare: 36    // Equal to minFare
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let minFare = results.first(where: { $0.rule.kind == .minimumFare })!
    XCTAssertTrue(minFare.isActive, "Fare == minFare")
    XCTAssertEqual(minFare.amount, 36, accuracy: 0.01)
  }

  func testMinimumFareInactiveWhenAboveThreshold() {
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 5.0,
      elapsedTime: 1200,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 14),
      currentFare: 90
    )
    let results = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)

    let minFare = results.first(where: { $0.rule.kind == .minimumFare })!
    XCTAssertFalse(minFare.isActive, "Fare 90 > minFare 36")
  }

  // MARK: - NYC Speed-Based Model

  func testNYCSurchargesEvaluation() {
    // Wednesday 17:00 — rush hour and no night
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 18  // Wednesday
    components.hour = 17
    components.minute = 0
    let wedEvening = Calendar.current.date(from: components)!

    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 5.0,
      elapsedTime: 900,
      waitingTime: 0,
      currentSpeedKph: 25,
      tripDate: wedEvening,
      currentFare: 15
    )
    let results = FareRuleEvaluator.evaluate(profile: nycProfile, context: context)

    let nightResult = results.first(where: { $0.rule.id == "surcharge:nyc-night" })!
    XCTAssertFalse(nightResult.isActive, "17:00 is before 20:00")

    let rushResult = results.first(where: { $0.rule.id == "surcharge:nyc-rush" })!
    XCTAssertTrue(rushResult.isActive, "Wed 17:00 is weekday rush hour")
    XCTAssertEqual(rushResult.amount, 2.50, accuracy: 0.01)

    let mtaResult = results.first(where: { $0.rule.id == "surcharge:nyc-mta" })!
    XCTAssertTrue(mtaResult.isActive, "MTA Tax always active")
    XCTAssertEqual(mtaResult.amount, 0.50, accuracy: 0.01)

    let improvementResult = results.first(where: { $0.rule.id == "surcharge:nyc-improvement" })!
    XCTAssertTrue(improvementResult.isActive, "Improvement always active")
    XCTAssertEqual(improvementResult.amount, 1.00, accuracy: 0.01)
  }

  func testNYCSpeedBasedChargePresent() {
    let rules = FareRuleEvaluator.allRules(from: nycProfile)
    let speedRule = rules.first(where: { $0.kind == .speedBasedCharge })
    XCTAssertNotNil(speedRule)
    XCTAssertTrue(speedRule!.description.contains("19"), "Should mention 19 km/h threshold")
  }

  // MARK: - RateSnapshot Overload

  func testEvaluateFromRateSnapshot() {
    let snapshot = RateSnapshot(
      settings: .bengaluruDefault,
      cityId: "bengaluru",
      cityName: "Bengaluru",
      vehicleType: VehicleTypeCatalog.autoRickshaw,
      currencyCode: "INR",
      surcharges: [
        FareSurcharge(id: "bengaluru-night", name: "Night", type: .percentageOfFare(0.50),
                      conditions: [.timeOfDay(start: 22, end: 5)])
      ]
    )
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.0,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 23),
      currentFare: 54
    )

    let results = FareRuleEvaluator.evaluate(snapshot: snapshot, context: context)
    XCTAssertFalse(results.isEmpty)

    let nightSurcharge = results.first(where: { $0.rule.kind == .surcharge })!
    XCTAssertTrue(nightSurcharge.isActive, "Night surcharge active at 23:00")
  }

  // MARK: - Amount Accuracy vs FareCalculator

  func testAmountsMatchFareCalculatorBreakdown() {
    let profile = bengaluruProfile
    let settings = MeterSettings(profile: profile)
    let calculator = FareCalculator(settings: settings)

    let distanceKm = 5.0
    let elapsedTime: TimeInterval = 1200
    let waitingTime: TimeInterval = 25 * 60
    let tripDate = dayDate(hour: 14)

    let breakdown = calculator.calculateFare(
      distanceKm: distanceKm,
      elapsedTime: elapsedTime,
      waitingTime: waitingTime,
      currentSpeedKph: 30,
      surcharges: profile.surcharges,
      tripDate: tripDate,
      isNight: false
    )

    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: distanceKm,
      elapsedTime: elapsedTime,
      waitingTime: waitingTime,
      currentSpeedKph: 30,
      tripDate: tripDate,
      currentFare: breakdown.total
    )
    let results = FareRuleEvaluator.evaluate(profile: profile, context: context)

    let baseFareResult = results.first(where: { $0.rule.kind == .baseFare })!
    XCTAssertEqual(baseFareResult.amount, breakdown.baseFare, accuracy: 0.01)

    let distanceResult = results.first(where: { $0.rule.kind == .distanceCharge })!
    XCTAssertEqual(distanceResult.amount, breakdown.distanceFare, accuracy: 0.01)

    let waitingResult = results.first(where: { $0.rule.kind == .waitingCharge })!
    XCTAssertEqual(waitingResult.amount, breakdown.waitingFare, accuracy: 0.01)
  }

  // MARK: - Edge Cases

  func testProfileWithNoSurchargesUsesLegacyNightMultiplier() {
    // Create a profile without surcharges but with night multiplier
    let profile = CityFareProfile(
      id: "test-legacy",
      cityId: "test",
      name: "Test City",
      vehicleType: VehicleTypeCatalog.taxi,
      cityKey: CityKey(city: "Test", region: nil, countryCode: "IN", currencyCode: "INR"),
      rates: FareRates(baseFare: 50, perKmRate: 20, perMinuteRate: 0, includedKm: 2.0, minFare: 50),
      multipliers: FareMultipliers(night: 1.5),
      nightWindow: NightFareWindow(startHour: 22, endHour: 5),
      waitCharges: WaitingChargePolicy(freeWaitMinutes: 5, waitIntervalMinutes: 15, waitIntervalCharge: 10),
      effectiveFrom: Date()
    )

    let rules = FareRuleEvaluator.allRules(from: profile)
    let nightRule = rules.first(where: { $0.id == "nightMultiplier" })
    XCTAssertNotNil(nightRule, "Should generate legacy night multiplier rule")
    XCTAssertTrue(nightRule!.description.contains("+50%"))
  }

  func testProfileWithSurchargesDoesNotGenerateLegacyNightRule() {
    let rules = FareRuleEvaluator.allRules(from: bengaluruProfile)
    let legacyNight = rules.first(where: { $0.id == "nightMultiplier" })
    XCTAssertNil(legacyNight, "Should not have legacy night rule when surcharges exist")
  }

  func testAllRulesCountMatchesEvaluatedCount() {
    let allRules = FareRuleEvaluator.allRules(from: bengaluruProfile)
    let context = FareRuleContext(
      tripState: .inProgress,
      distanceKm: 3.0,
      elapsedTime: 600,
      waitingTime: 0,
      currentSpeedKph: 30,
      tripDate: dayDate(hour: 14),
      currentFare: 54
    )
    let evaluated = FareRuleEvaluator.evaluate(profile: bengaluruProfile, context: context)
    XCTAssertEqual(allRules.count, evaluated.count, "Every rule should be evaluated")
  }
}
