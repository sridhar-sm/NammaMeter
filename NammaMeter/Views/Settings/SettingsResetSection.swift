import SwiftUI

struct SettingsResetSection: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    Section {
      Button {
        settingsStore.resetToDefaults()
      } label: {
        Text("Reset to defaults")
      }
      .accessibilityIdentifier("settings.resetButton")
    }
  }
}
