import SwiftUI

struct FieldErrorText: View {
  let message: String
  let severity: ValidationError.Severity

  init(message: String, severity: ValidationError.Severity = .error) {
    self.message = message
    self.severity = severity
  }

  var body: some View {
    Text(message)
      .font(FontPresets.Body.small)
      .foregroundStyle(color)
  }

  private var color: Color {
    switch severity {
    case .error:
      return .red
    case .warning:
      return .orange
    case .info:
      return .secondary
    }
  }
}
