import Observation

@Observable
final class FormState<Validator: FormValidator> {
  var input: Validator.Input {
    didSet {
      validate()
    }
  }

  private(set) var errors: [ValidationError] = []
  private(set) var errorsByField: [String: [ValidationError]] = [:]

  @ObservationIgnored let validator: Validator

  init(input: Validator.Input, validator: Validator) {
    self.input = input
    self.validator = validator
    validate()
  }

  var isValid: Bool {
    !errors.contains { $0.severity == .error }
  }

  var hasBlockingErrors: Bool {
    !isValid
  }

  func validate() {
    errors = validator.validate(input)
    errorsByField = Dictionary(grouping: errors, by: \.field)
  }

  func hasError(for field: String) -> Bool {
    !(errorsByField[field] ?? []).isEmpty
  }

  func errors(for field: String) -> [ValidationError] {
    errorsByField[field] ?? []
  }

  func issue(for field: String) -> ValidationError? {
    let issues = errorsByField[field] ?? []
    return issues.first { $0.severity == .error }
      ?? issues.first { $0.severity == .warning }
      ?? issues.first
  }

  func errorMessage(for field: String) -> String? {
    issue(for: field)?.message
  }
}
