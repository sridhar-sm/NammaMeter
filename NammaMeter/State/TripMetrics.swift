import Foundation
import Observation

@Observable
final class TripMetrics {
  private(set) var distanceMeters: Double = 0
  private(set) var elapsedSeconds: TimeInterval = 0
  private(set) var waitingSeconds: TimeInterval = 0

  func addDistance(_ meters: Double) {
    distanceMeters += meters
  }

  func addElapsedTime(_ seconds: TimeInterval) {
    elapsedSeconds += seconds
  }

  func setElapsedTime(_ seconds: TimeInterval) {
    elapsedSeconds = seconds
  }

  func addWaitingTime(_ seconds: TimeInterval) {
    waitingSeconds += seconds
  }

  func setWaitingTime(_ seconds: TimeInterval) {
    waitingSeconds = seconds
  }

  var distanceKm: Double {
    distanceMeters / 1000
  }

  var formattedDistance: String {
    String(format: "%.2f km", distanceKm)
  }

  var formattedElapsed: String {
    let totalSeconds = max(Int(elapsedSeconds), 0)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  func reset() -> TripMetrics {
    TripMetrics()
  }
}
