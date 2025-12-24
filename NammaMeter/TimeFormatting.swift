import Foundation

func formattedElapsed(_ interval: TimeInterval) -> String {
  let totalSeconds = max(Int(interval), 0)
  let hours = totalSeconds / 3600
  let minutes = (totalSeconds % 3600) / 60
  let seconds = totalSeconds % 60

  if hours > 0 {
    return String(format: "%dh %dm %ds", hours, minutes, seconds)
  }
  return String(format: "%dm %ds", minutes, seconds)
}
