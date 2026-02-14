import Foundation

struct FareCalculator: FareCalculationStrategy {
  let settings: MeterSettings
  let perMinuteWhenSlow: Double?
  let slowSpeedThresholdKph: Double?

  init(settings: MeterSettings, perMinuteWhenSlow: Double? = nil, slowSpeedThresholdKph: Double? = nil) {
    self.settings = settings
    self.perMinuteWhenSlow = perMinuteWhenSlow
    self.slowSpeedThresholdKph = slowSpeedThresholdKph
  }

  // MARK: - Legacy method (existing callers)

  func calculateFare(
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    isNight: Bool
  ) -> Double {
    let breakdown = calculateFare(
      distanceKm: distanceKm,
      elapsedTime: elapsedTime,
      waitingTime: waitingTime,
      currentSpeedKph: nil,
      surcharges: nil,
      tripDate: Date(),
      isNight: isNight
    )
    return breakdown.total
  }

  // MARK: - FareCalculationStrategy

  func calculateFare(
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    currentSpeedKph: Double?,
    surcharges: [FareSurcharge]?,
    tripDate: Date,
    isNight: Bool
  ) -> FareBreakdown {
    let baseFare = settings.baseFare
    let distanceFare: Double
    let timeFare: Double
    let waitingFare: Double

    if let perMinSlow = perMinuteWhenSlow, slowSpeedThresholdKph != nil {
      // Speed-based model: max(distance fare, time fare), no separate waiting
      distanceFare = calculateDistanceFare(distanceKm)
      let minutes = elapsedTime / 60
      timeFare = minutes * perMinSlow
      waitingFare = 0
    } else {
      // Standard model: distance + time + waiting
      distanceFare = calculateDistanceFare(distanceKm)
      timeFare = calculateTimeFare(elapsedTime)
      waitingFare = calculateWaitingFare(waitingTime)
    }

    let subtotal: Double
    if perMinuteWhenSlow != nil && slowSpeedThresholdKph != nil {
      subtotal = baseFare + max(distanceFare, timeFare)
    } else {
      subtotal = baseFare + distanceFare + timeFare + waitingFare
    }

    // Surcharge path vs legacy night multiplier path
    let appliedSurcharges: [AppliedSurcharge]
    let surchargeTotal: Double
    let total: Double

    if let fareSurcharges = surcharges {
      appliedSurcharges = SurchargeCalculator.evaluate(fareSurcharges, subtotal: subtotal, at: tripDate)
      surchargeTotal = appliedSurcharges.reduce(0) { $0 + $1.amount }
      total = max(settings.minFare, subtotal + surchargeTotal)
    } else {
      // Legacy path: use night multiplier
      let multiplier = isNight ? settings.nightMultiplier : 1.0
      let adjusted = subtotal * multiplier
      appliedSurcharges = []
      surchargeTotal = adjusted - subtotal
      total = max(settings.minFare, adjusted)
    }

    return FareBreakdown(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      waitingFare: waitingFare,
      subtotal: subtotal,
      surcharges: appliedSurcharges,
      surchargeTotal: surchargeTotal,
      total: total
    )
  }

  // MARK: - Component calculations

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
