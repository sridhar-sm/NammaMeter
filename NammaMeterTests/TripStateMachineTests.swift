import Foundation
import XCTest
@testable import NammaMeter

@MainActor
final class TripStateMachineTests: XCTestCase {
  private var stateMachine: TripStateMachine!

  override func setUp() async throws {
    stateMachine = TripStateMachine()
  }

  func testInitialState() {
    XCTAssertEqual(stateMachine.tripState, .forHire)
    XCTAssertFalse(stateMachine.isOnTrip)
  }

  func testStateTransitions() {
    XCTAssertTrue(stateMachine.stateHistory.isEmpty)

    stateMachine.startTrip()
    XCTAssertTrue(stateMachine.isOnTrip)
    XCTAssertEqual(stateMachine.tripState, .inProgress)

    stateMachine.completeTrip(trip: makeTrip())
    XCTAssertFalse(stateMachine.isOnTrip)
    XCTAssertEqual(stateMachine.tripState, .complete)

    stateMachine.resetToForHire()
    XCTAssertFalse(stateMachine.isOnTrip)
    XCTAssertEqual(stateMachine.tripState, .forHire)
  }

  func testInvalidTransitionsAreNoOps() {
    stateMachine.startTrip()
    stateMachine.startTrip()
    XCTAssertEqual(stateMachine.stateHistory.count, 1)
  }
}

private func makeTrip() -> Trip {
  Trip(
    id: UUID(),
    startDate: Date(),
    endDate: Date(),
    distanceMeters: 0,
    duration: 0,
    fare: 0,
    points: [],
    conditions: .clear,
    rateSnapshot: RateSnapshot(settings: .bengaluruDefault),
    multiplier: 1,
    waitingDuration: 0
  )
}
