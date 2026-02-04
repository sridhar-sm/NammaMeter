import XCTest
@testable import NammaMeter

final class FareCalculatorTests: XCTestCase {
  private var calculator: FareCalculator!
  private var settings: MeterSettings!

  override func setUp() {
    super.setUp()
    settings = MeterSettings.bengaluruDefault
    calculator = FareCalculator(settings: settings)
  }

  func testBaseFareCharged() {
    let fare = calculator.calculateFare(
      distanceKm: 0,
      elapsedTime: 0,
      waitingTime: 0,
      isNight: false
    )

    XCTAssertEqual(fare, settings.minFare)
  }

  func testDistanceFareCalculation() {
    let distanceKm = settings.includedKm + 3.0
    let fare = calculator.calculateFare(
      distanceKm: distanceKm,
      elapsedTime: 0,
      waitingTime: 0,
      isNight: false
    )

    let expectedExtra = (distanceKm - settings.includedKm) * settings.perKmRate
    let expected = max(settings.minFare, settings.baseFare + expectedExtra)
    XCTAssertEqual(fare, expected, accuracy: 0.01)
  }

  func testNightMultiplierApplied() {
    let distanceKm = settings.includedKm + 3.0
    let dayFare = calculator.calculateFare(
      distanceKm: distanceKm,
      elapsedTime: 300,
      waitingTime: 0,
      isNight: false
    )

    let nightFare = calculator.calculateFare(
      distanceKm: distanceKm,
      elapsedTime: 300,
      waitingTime: 0,
      isNight: true
    )

    let expected = max(settings.minFare, dayFare * settings.nightMultiplier)
    XCTAssertEqual(nightFare, expected, accuracy: 0.01)
  }

  func testWaitingFareCalculation() {
    let freeWaitMinutes = settings.freeWaitMinutes
    let waitingTime = (freeWaitMinutes + 1) * 60

    let fare = calculator.calculateFare(
      distanceKm: 0,
      elapsedTime: 0,
      waitingTime: waitingTime,
      isNight: false
    )

    let expectedWaitCharge = settings.waitIntervalCharge
    let expected = max(settings.minFare, settings.baseFare + expectedWaitCharge)
    XCTAssertEqual(fare, expected, accuracy: 0.01)
  }
}
