import SwiftUI

struct SettingsHeader: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Meter Settings")
        .font(FontPresets.Display.title)
      Text("ಮೀಟರ್ ಸೆಟ್ಟಿಂಗ್ಸ್")
        .font(FontPresets.Body.medium)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}
