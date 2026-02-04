import XCTest
@testable import NammaMeter

@MainActor
final class WaitingChargeTests: XCTestCase {
  private let store = MeterStore()

  private func charge(
    waitingMinutes: Double,
    freeWaitMinutes: Double = 5,
    intervalMinutes: Double = 15,
    intervalCharge: Double = 10
  ) -> Double {
    store.calculateWaitingCharge(
      waitingDuration: waitingMinutes * 60,
      freeWaitMinutes: freeWaitMinutes,
      waitIntervalMinutes: intervalMinutes,
      waitIntervalCharge: intervalCharge
    )
  }

  func testFreeWaitPeriodIsNotCharged() {
    let cases: [(Double, Double)] = [
      (0, 0),
      (3, 0),
      (5, 0)
    ]

    for (waitingMinutes, expected) in cases {
      XCTAssertEqual(charge(waitingMinutes: waitingMinutes), expected, "waitingMinutes=\(waitingMinutes)")
    }
  }

  func testIntervalBillingAfterFreeWait() {
    let cases: [(Double, Double)] = [
      (6, 10),
      (20, 10),
      (21, 20),
      (35, 20),
      (36, 30)
    ]

    for (waitingMinutes, expected) in cases {
      XCTAssertEqual(charge(waitingMinutes: waitingMinutes), expected, "waitingMinutes=\(waitingMinutes)")
    }
  }

  func testEdgeCases() {
    XCTAssertEqual(charge(waitingMinutes: 10, intervalMinutes: 0), 0)
    XCTAssertEqual(charge(waitingMinutes: 10, intervalMinutes: -5), 0)
    XCTAssertEqual(charge(waitingMinutes: 10, freeWaitMinutes: 0), 10)
    XCTAssertEqual(charge(waitingMinutes: 20, intervalCharge: 0), 0)
  }
}
