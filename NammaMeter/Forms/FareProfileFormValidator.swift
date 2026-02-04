import Foundation

enum FareProfileFormField: String {
  case effectiveFrom
  case baseFare
  case perKmRate
  case minFare
  case includedKm
  case nightMultiplier
  case nightStartHour
  case nightEndHour
  case freeWaitMinutes
  case waitIntervalMinutes
  case waitIntervalCharge
}

struct FareProfileFormData {
  var effectiveFrom: Date
  var baseFare: Double
  var perKmRate: Double
  var minFare: Double
  var includedKm: Double
  var nightMultiplier: Double
  var nightStartHour: Int
  var nightEndHour: Int
  var freeWaitMinutes: Double
  var waitIntervalMinutes: Double
  var waitIntervalCharge: Double
}

struct FareProfileFormValidator: FormValidator {
  private let baseFareValidator = DoubleRangeValidator(
    field: FareProfileFormField.baseFare.rawValue,
    label: "Base fare",
    min: 0,
    max: nil
  )
  private let perKmValidator = DoubleRangeValidator(
    field: FareProfileFormField.perKmRate.rawValue,
    label: "Per-km rate",
    min: 0,
    max: nil
  )
  private let minFareValidator = DoubleRangeValidator(
    field: FareProfileFormField.minFare.rawValue,
    label: "Minimum fare",
    min: 0,
    max: nil
  )
  private let includedKmValidator = DoubleRangeValidator(
    field: FareProfileFormField.includedKm.rawValue,
    label: "Included km",
    min: 0,
    max: nil
  )
  private let nightMultiplierValidator = DoubleRangeValidator(
    field: FareProfileFormField.nightMultiplier.rawValue,
    label: "Night multiplier",
    min: 1,
    max: nil
  )
  private let nightStartHourValidator = IntRangeValidator(
    field: FareProfileFormField.nightStartHour.rawValue,
    label: "Night start hour",
    min: 0,
    max: 23
  )
  private let nightEndHourValidator = IntRangeValidator(
    field: FareProfileFormField.nightEndHour.rawValue,
    label: "Night end hour",
    min: 0,
    max: 23
  )
  private let freeWaitValidator = DoubleRangeValidator(
    field: FareProfileFormField.freeWaitMinutes.rawValue,
    label: "Free wait minutes",
    min: 0,
    max: nil
  )
  private let waitIntervalValidator = DoubleRangeValidator(
    field: FareProfileFormField.waitIntervalMinutes.rawValue,
    label: "Wait interval minutes",
    min: 0,
    max: nil
  )
  private let waitIntervalChargeValidator = DoubleRangeValidator(
    field: FareProfileFormField.waitIntervalCharge.rawValue,
    label: "Wait interval charge",
    min: 0,
    max: nil
  )

  func validate(_ input: FareProfileFormData) -> [ValidationError] {
    var errors: [ValidationError] = []

    errors.append(contentsOf: baseFareValidator.validate(input.baseFare))
    errors.append(contentsOf: perKmValidator.validate(input.perKmRate))
    errors.append(contentsOf: minFareValidator.validate(input.minFare))
    errors.append(contentsOf: includedKmValidator.validate(input.includedKm))
    errors.append(contentsOf: nightMultiplierValidator.validate(input.nightMultiplier))

    errors.append(contentsOf: nightStartHourValidator.validate(input.nightStartHour))
    errors.append(contentsOf: nightEndHourValidator.validate(input.nightEndHour))

    errors.append(contentsOf: freeWaitValidator.validate(input.freeWaitMinutes))
    errors.append(contentsOf: waitIntervalValidator.validate(input.waitIntervalMinutes))
    errors.append(contentsOf: waitIntervalChargeValidator.validate(input.waitIntervalCharge))

    if input.minFare < input.baseFare {
      errors.append(ValidationError(
        field: FareProfileFormField.minFare.rawValue,
        message: "Minimum fare is below base fare; the base fare will still apply.",
        severity: .warning
      ))
    }

    if input.waitIntervalMinutes == 0 {
      errors.append(ValidationError(
        field: FareProfileFormField.waitIntervalMinutes.rawValue,
        message: "Wait interval minutes is 0; waiting charges will be disabled.",
        severity: .warning
      ))
    }

    if input.nightStartHour == input.nightEndHour {
      errors.append(ValidationError(
        field: FareProfileFormField.nightEndHour.rawValue,
        message: "Night start and end hours are the same; night fares will not apply.",
        severity: .warning
      ))
    }

    return errors
  }
}
