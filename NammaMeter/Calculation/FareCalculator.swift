import Foundation

struct FareCalculator {
  let settings: MeterSettings

  func calculateFare(
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    isNight: Bool
  ) -> Double {
    let baseFare = settings.baseFare
    let distanceFare = calculateDistanceFare(distanceKm)
    let timeFare = calculateTimeFare(elapsedTime)
    let waitFare = calculateWaitingFare(waitingTime)

    let subtotal = baseFare + distanceFare + timeFare + waitFare
    let multiplier = isNight ? settings.nightMultiplier : 1.0
    let adjusted = subtotal * multiplier

    return max(settings.minFare, adjusted)
  }

  func calculateDistanceFare(_ distanceKm: Double) -> Double {
    guard distanceKm > settings.includedKm else { return 0 }
    let extraKm = distanceKm - settings.includedKm
    return extraKm * settings.perKmRate
  }

  func calculateTimeFare(_ elapsedTime: TimeInterval) -> Double {
    let minutes = elapsedTime / 60
    return minutes * settings.perMinuteRate
  }

  func calculateWaitingFare(_ waitingTime: TimeInterval) -> Double {
    Self.calculateWaitingCharge(
      waitingDuration: waitingTime,
      freeWaitMinutes: settings.freeWaitMinutes,
      waitIntervalMinutes: settings.waitIntervalMinutes,
      waitIntervalCharge: settings.waitIntervalCharge
    )
  }

  static func calculateWaitingCharge(
    waitingDuration: TimeInterval,
    freeWaitMinutes: Double,
    waitIntervalMinutes: Double,
    waitIntervalCharge: Double
  ) -> Double {
    let waitingMinutes = waitingDuration / 60
    let chargeableMinutes = max(0, waitingMinutes - freeWaitMinutes)
    guard waitIntervalMinutes > 0 else { return 0 }
    let intervals = ceil(chargeableMinutes / waitIntervalMinutes)
    return intervals * waitIntervalCharge
  }

  func validateSettings() -> [String] {
    var errors: [String] = []

    if settings.baseFare < 0 {
      errors.append("Base fare cannot be negative")
    }
    if settings.perKmRate < 0 {
      errors.append("Per-km rate cannot be negative")
    }
    if settings.includedKm < 0 {
      errors.append("Included km cannot be negative")
    }
    if settings.minFare < 0 {
      errors.append("Minimum fare cannot be negative")
    }

    return errors
  }
}
