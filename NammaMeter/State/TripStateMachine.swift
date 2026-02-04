import Foundation
import Observation

@MainActor
@Observable
final class TripStateMachine {
  enum State {
    case forHire
    case inProgress(startTime: Date)
    case complete(trip: Trip)
  }

  private(set) var currentState: State = .forHire
  private(set) var stateHistory: [State] = []

  func startTrip(startTime: Date = Date()) {
    guard case .forHire = currentState else { return }
    let newState = State.inProgress(startTime: startTime)
    stateHistory.append(newState)
    currentState = newState
  }

  func completeTrip(trip: Trip) {
    guard case .inProgress = currentState else { return }
    let newState = State.complete(trip: trip)
    stateHistory.append(newState)
    currentState = newState
  }

  func resetToForHire() {
    guard case .complete = currentState else { return }
    currentState = .forHire
    stateHistory.append(.forHire)
  }

  var isOnTrip: Bool {
    if case .inProgress = currentState { return true }
    return false
  }

  var tripState: TripMeterState {
    switch currentState {
    case .forHire:
      return .forHire
    case .inProgress:
      return .inProgress
    case .complete:
      return .complete
    }
  }

  var startTime: Date? {
    if case let .inProgress(startTime) = currentState {
      return startTime
    }
    return nil
  }

  var completedTrip: Trip? {
    if case let .complete(trip) = currentState {
      return trip
    }
    return nil
  }
}
