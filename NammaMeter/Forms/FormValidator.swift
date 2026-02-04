import Foundation

struct ValidationError: Identifiable {
  let id = UUID()
  let field: String
  let message: String
  let severity: Severity

  enum Severity {
    case error
    case warning
    case info
  }
}

protocol FormValidator {
  associatedtype Input
  func validate(_ input: Input) -> [ValidationError]
}

extension FormValidator {
  func isValid(_ input: Input) -> Bool {
    validate(input).isEmpty
  }
}

struct StringValidator: FormValidator {
  let field: String
  let label: String
  let minLength: Int
  let maxLength: Int?
  let allowEmpty: Bool
  let trimWhitespace: Bool

  func validate(_ input: String) -> [ValidationError] {
    let value = trimWhitespace ? input.trimmingCharacters(in: .whitespacesAndNewlines) : input
    if value.isEmpty && allowEmpty {
      return []
    }

    var errors: [ValidationError] = []
    if value.isEmpty {
      errors.append(ValidationError(
        field: field,
        message: "\(label) cannot be empty.",
        severity: .error
      ))
      return errors
    }

    if value.count < minLength {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at least \(minLength) characters.",
        severity: .error
      ))
    }

    if let maxLength, value.count > maxLength {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at most \(maxLength) characters.",
        severity: .error
      ))
    }

    return errors
  }
}

struct DoubleRangeValidator: FormValidator {
  let field: String
  let label: String
  let min: Double?
  let max: Double?

  func validate(_ input: Double) -> [ValidationError] {
    guard !input.isNaN, !input.isInfinite else {
      return [ValidationError(field: field, message: "\(label) must be a number.", severity: .error)]
    }

    var errors: [ValidationError] = []
    if let min, input < min {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at least \(format(min)).",
        severity: .error
      ))
    }
    if let max, input > max {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at most \(format(max)).",
        severity: .error
      ))
    }

    return errors
  }

  private func format(_ value: Double) -> String {
    if value.rounded(.towardZero) == value {
      return String(Int(value))
    }
    return String(format: "%.2f", value)
  }
}

struct IntRangeValidator: FormValidator {
  let field: String
  let label: String
  let min: Int
  let max: Int

  func validate(_ input: Int) -> [ValidationError] {
    var errors: [ValidationError] = []
    if input < min {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at least \(min).",
        severity: .error
      ))
    }
    if input > max {
      errors.append(ValidationError(
        field: field,
        message: "\(label) must be at most \(max).",
        severity: .error
      ))
    }

    return errors
  }
}
