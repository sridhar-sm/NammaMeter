import Foundation

enum FareRuleEvaluator {

  // MARK: - Public API

  static func allRules(from profile: CityFareProfile) -> [FareRule] {
    buildRules(
      rates: profile.rates,
      waitCharges: profile.waitCharges,
      nightWindow: profile.nightWindow,
      multipliers: profile.multipliers,
      surcharges: profile.surcharges,
      currencyCode: profile.cityKey.currencyCode
    )
  }

  static func allRules(from snapshot: RateSnapshot) -> [FareRule] {
    let surcharges = snapshot.surcharges ?? []
    return buildRules(
      rates: FareRates(
        baseFare: snapshot.baseFare,
        perKmRate: snapshot.perKmRate,
        perMinuteRate: snapshot.perMinuteRate,
        includedKm: snapshot.includedKm,
        minFare: snapshot.minFare
      ),
      waitCharges: WaitingChargePolicy(
        freeWaitMinutes: snapshot.freeWaitMinutes,
        waitIntervalMinutes: snapshot.waitIntervalMinutes,
        waitIntervalCharge: snapshot.waitIntervalCharge
      ),
      nightWindow: NightFareWindow(
        startHour: snapshot.nightStartHour,
        endHour: snapshot.nightEndHour
      ),
      multipliers: FareMultipliers(night: snapshot.nightMultiplier),
      surcharges: surcharges.isEmpty ? nil : surcharges,
      currencyCode: snapshot.currencyCode ?? "INR"
    )
  }

  static func evaluate(
    profile: CityFareProfile,
    context: FareRuleContext
  ) -> [EvaluatedFareRule] {
    let rules = allRules(from: profile)
    return rules.map { rule in
      evaluateRule(
        rule,
        rates: profile.rates,
        waitCharges: profile.waitCharges,
        nightWindow: profile.nightWindow,
        multipliers: profile.multipliers,
        surcharges: profile.surcharges,
        context: context
      )
    }
  }

  static func evaluate(
    snapshot: RateSnapshot,
    context: FareRuleContext
  ) -> [EvaluatedFareRule] {
    let rules = allRules(from: snapshot)
    let rates = FareRates(
      baseFare: snapshot.baseFare,
      perKmRate: snapshot.perKmRate,
      perMinuteRate: snapshot.perMinuteRate,
      includedKm: snapshot.includedKm,
      minFare: snapshot.minFare
    )
    let waitCharges = WaitingChargePolicy(
      freeWaitMinutes: snapshot.freeWaitMinutes,
      waitIntervalMinutes: snapshot.waitIntervalMinutes,
      waitIntervalCharge: snapshot.waitIntervalCharge
    )
    let nightWindow = NightFareWindow(
      startHour: snapshot.nightStartHour,
      endHour: snapshot.nightEndHour
    )
    let multipliers = FareMultipliers(night: snapshot.nightMultiplier)

    return rules.map { rule in
      evaluateRule(
        rule,
        rates: rates,
        waitCharges: waitCharges,
        nightWindow: nightWindow,
        multipliers: multipliers,
        surcharges: snapshot.surcharges,
        context: context
      )
    }
  }

  // MARK: - Rule Building

  private static func buildRules(
    rates: FareRates,
    waitCharges: WaitingChargePolicy,
    nightWindow: NightFareWindow,
    multipliers: FareMultipliers,
    surcharges: [FareSurcharge]?,
    currencyCode: String
  ) -> [FareRule] {
    let sym = currencySymbol(for: currencyCode)
    var rules: [FareRule] = []

    let baseFmt = formatAmount(rates.baseFare, currencyCode: currencyCode)
    let includedFmt = rates.includedKm.formatted(.number.precision(.fractionLength(1)))
    rules.append(FareRule(
      id: "baseFare",
      kind: .baseFare,
      label: "Base Fare",
      description: "Base fare \(sym)\(baseFmt) for first \(includedFmt) km"
    ))

    if rates.perKmRate > 0 {
      let perKmFmt = formatAmount(rates.perKmRate, currencyCode: currencyCode)
      rules.append(FareRule(
        id: "distanceCharge",
        kind: .distanceCharge,
        label: "Distance Charge",
        description: "Distance charge \(sym)\(perKmFmt) per km after \(includedFmt) km"
      ))
    }

    if rates.perMinuteRate > 0 {
      let perMinFmt = formatAmount(rates.perMinuteRate, currencyCode: currencyCode)
      rules.append(FareRule(
        id: "timeCharge",
        kind: .timeCharge,
        label: "Time Charge",
        description: "Time charge \(sym)\(perMinFmt) per minute"
      ))
    }

    if waitCharges.waitIntervalCharge > 0 && waitCharges.waitIntervalMinutes > 0 {
      let freeWaitFmt = waitCharges.freeWaitMinutes.formatted(.number.precision(.fractionLength(0)))
      let intervalFmt = waitCharges.waitIntervalMinutes.formatted(.number.precision(.fractionLength(0)))
      let chargeFmt = formatAmount(waitCharges.waitIntervalCharge, currencyCode: currencyCode)
      rules.append(FareRule(
        id: "waitingCharge",
        kind: .waitingCharge,
        label: "Waiting Charge",
        description: "Waiting: first \(freeWaitFmt) min free, then \(sym)\(chargeFmt) every \(intervalFmt) min"
      ))
    }

    if let perMinSlow = rates.perMinuteWhenSlow,
       let threshold = rates.slowSpeedThresholdKph {
      let slowFmt = formatAmount(perMinSlow, currencyCode: currencyCode)
      let threshFmt = threshold.formatted(.number.precision(.fractionLength(0)))
      rules.append(FareRule(
        id: "speedBasedCharge",
        kind: .speedBasedCharge,
        label: "Slow Speed Charge",
        description: "Time charge \(sym)\(slowFmt)/min when below \(threshFmt) km/h"
      ))
    }

    let minFareFmt = formatAmount(rates.minFare, currencyCode: currencyCode)
    rules.append(FareRule(
      id: "minimumFare",
      kind: .minimumFare,
      label: "Minimum Fare",
      description: "Minimum fare \(sym)\(minFareFmt)"
    ))

    // Legacy night multiplier (for profiles without surcharges)
    if surcharges == nil || surcharges?.isEmpty == true {
      if multipliers.night > 1.0 {
        let nightPercent = Int((multipliers.night - 1) * 100)
        let start = String(format: "%02d:00", nightWindow.startHour)
        let end = String(format: "%02d:00", nightWindow.endHour)
        rules.append(FareRule(
          id: "nightMultiplier",
          kind: .surcharge,
          label: "Night Surcharge",
          description: "Night surcharge +\(nightPercent)% (\(start)-\(end))"
        ))
      }
    }

    // Explicit surcharges
    if let entries = surcharges {
      for entry in entries {
        let desc = surchargeDescription(entry, currencyCode: currencyCode)
        rules.append(FareRule(
          id: "surcharge:\(entry.id)",
          kind: .surcharge,
          label: entry.name,
          description: desc
        ))
      }
    }

    return rules
  }

  // MARK: - Rule Evaluation

  private static func evaluateRule(
    _ rule: FareRule,
    rates: FareRates,
    waitCharges: WaitingChargePolicy,
    nightWindow: NightFareWindow,
    multipliers: FareMultipliers,
    surcharges: [FareSurcharge]?,
    context: FareRuleContext
  ) -> EvaluatedFareRule {
    let (isActive, amount) = computeActivation(
      rule: rule,
      rates: rates,
      waitCharges: waitCharges,
      nightWindow: nightWindow,
      multipliers: multipliers,
      surcharges: surcharges,
      context: context
    )
    return EvaluatedFareRule(rule: rule, isActive: isActive, amount: amount)
  }

  private static func computeActivation(
    rule: FareRule,
    rates: FareRates,
    waitCharges: WaitingChargePolicy,
    nightWindow: NightFareWindow,
    multipliers: FareMultipliers,
    surcharges: [FareSurcharge]?,
    context: FareRuleContext
  ) -> (isActive: Bool, amount: Double) {
    switch rule.kind {
    case .baseFare:
      return (true, rates.baseFare)

    case .distanceCharge:
      let extraKm = max(0, context.distanceKm - rates.includedKm)
      let amount = extraKm * rates.perKmRate
      return (extraKm > 0, amount)

    case .timeCharge:
      let minutes = context.elapsedTime / 60
      let amount = minutes * rates.perMinuteRate
      let isActive = context.tripState == .inProgress && amount > 0
      return (isActive, isActive ? amount : 0)

    case .waitingCharge:
      let amount = FareCalculator.calculateWaitingCharge(
        waitingDuration: context.waitingTime,
        freeWaitMinutes: waitCharges.freeWaitMinutes,
        waitIntervalMinutes: waitCharges.waitIntervalMinutes,
        waitIntervalCharge: waitCharges.waitIntervalCharge
      )
      return (amount > 0, amount)

    case .speedBasedCharge:
      guard let perMinSlow = rates.perMinuteWhenSlow,
            let threshold = rates.slowSpeedThresholdKph else {
        return (false, 0)
      }
      let minutes = context.elapsedTime / 60
      let timeFare = minutes * perMinSlow
      // In speed-based model, time fare is active when it exceeds distance fare
      let distanceFare = max(0, context.distanceKm - rates.includedKm) * rates.perKmRate
        + (rates.includedKm > 0 ? 0 : context.distanceKm * rates.perKmRate)
      let isActive: Bool
      if let speed = context.currentSpeedKph {
        isActive = speed < threshold
      } else {
        // No speed info — active if time fare >= distance fare (trip average)
        isActive = timeFare >= distanceFare
      }
      return (isActive, isActive ? timeFare : 0)

    case .minimumFare:
      let isActive = context.currentFare <= rates.minFare && context.tripState != .forHire
      return (isActive, isActive ? rates.minFare : 0)

    case .surcharge:
      return evaluateSurchargeRule(
        rule: rule,
        rates: rates,
        waitCharges: waitCharges,
        multipliers: multipliers,
        nightWindow: nightWindow,
        surcharges: surcharges,
        context: context
      )
    }
  }

  private static func evaluateSurchargeRule(
    rule: FareRule,
    rates: FareRates,
    waitCharges: WaitingChargePolicy,
    multipliers: FareMultipliers,
    nightWindow: NightFareWindow,
    surcharges: [FareSurcharge]?,
    context: FareRuleContext
  ) -> (isActive: Bool, amount: Double) {
    // Legacy night multiplier path
    if rule.id == "nightMultiplier" {
      let settings = MeterSettings(
        baseFare: rates.baseFare,
        perKmRate: rates.perKmRate,
        perMinuteRate: rates.perMinuteRate,
        includedKm: rates.includedKm,
        minFare: rates.minFare,
        nightMultiplier: multipliers.night,
        nightStartHour: nightWindow.startHour,
        nightEndHour: nightWindow.endHour,
        freeWaitMinutes: waitCharges.freeWaitMinutes,
        waitIntervalMinutes: waitCharges.waitIntervalMinutes,
        waitIntervalCharge: waitCharges.waitIntervalCharge,
        keepScreenAwakeDuringTrip: false
      )
      let isNight = settings.isNight(at: context.tripDate)
      if isNight {
        let subtotal = estimateSubtotal(rates: rates, waitCharges: waitCharges, context: context)
        let amount = subtotal * (multipliers.night - 1)
        return (true, amount)
      }
      return (false, 0)
    }

    // Explicit surcharge path
    guard let surchargeId = rule.id.split(separator: ":").last.map(String.init),
          let surcharge = surcharges?.first(where: { $0.id == surchargeId }) else {
      return (false, 0)
    }

    let isActive = surcharge.isActive(at: context.tripDate)
    guard isActive else { return (false, 0) }

    let subtotal = estimateSubtotal(rates: rates, waitCharges: waitCharges, context: context)
    let amount: Double
    switch surcharge.type {
    case .percentageOfFare(let pct):
      amount = subtotal * pct
    case .fixedAmount(let fixed):
      amount = fixed
    }
    return (true, amount)
  }

  private static func estimateSubtotal(
    rates: FareRates,
    waitCharges: WaitingChargePolicy? = nil,
    context: FareRuleContext
  ) -> Double {
    let distanceFare = max(0, context.distanceKm - rates.includedKm) * rates.perKmRate

    if let perMinSlow = rates.perMinuteWhenSlow, rates.slowSpeedThresholdKph != nil {
      let timeFare = (context.elapsedTime / 60) * perMinSlow
      return rates.baseFare + max(distanceFare, timeFare)
    } else {
      let timeFare = (context.elapsedTime / 60) * rates.perMinuteRate
      let wc = waitCharges ?? WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0)
      let waitingFare = FareCalculator.calculateWaitingCharge(
        waitingDuration: context.waitingTime,
        freeWaitMinutes: wc.freeWaitMinutes,
        waitIntervalMinutes: wc.waitIntervalMinutes,
        waitIntervalCharge: wc.waitIntervalCharge
      )
      return rates.baseFare + distanceFare + timeFare + waitingFare
    }
  }

  // MARK: - Formatting Helpers

  private static func currencySymbol(for code: String) -> String {
    switch code {
    case "INR": return "₹"
    case "USD": return "$"
    case "GBP": return "£"
    default: return code + " "
    }
  }

  private static func formatAmount(_ value: Double, currencyCode: String) -> String {
    switch currencyCode {
    case "INR":
      return value.formatted(.number.precision(.fractionLength(0)))
    default:
      return value.formatted(.number.precision(.fractionLength(2)))
    }
  }

  private static func surchargeDescription(_ surcharge: FareSurcharge, currencyCode: String) -> String {
    let sym = currencySymbol(for: currencyCode)
    let typeDesc: String
    switch surcharge.type {
    case .percentageOfFare(let pct):
      typeDesc = "+\(Int(pct * 100))% of fare"
    case .fixedAmount(let amount):
      typeDesc = "\(sym)\(formatAmount(amount, currencyCode: currencyCode))"
    }

    let conditionDesc: String
    if surcharge.conditions.isEmpty || surcharge.conditions.allSatisfy({ $0.isAlways }) {
      conditionDesc = "always"
    } else if let cond = surcharge.conditions.first, let start = cond.startHour, let end = cond.endHour {
      let startFmt = String(format: "%02d:00", start)
      let endFmt = String(format: "%02d:00", end)
      if cond.daysOfWeek != nil {
        conditionDesc = "weekdays \(startFmt)-\(endFmt)"
      } else {
        conditionDesc = "\(startFmt)-\(endFmt)"
      }
    } else {
      conditionDesc = "conditional"
    }

    return "\(surcharge.name) \(typeDesc) (\(conditionDesc))"
  }
}
