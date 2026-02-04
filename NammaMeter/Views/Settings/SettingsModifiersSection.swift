import SwiftUI

struct SettingsModifiersSection: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    Section(header: SectionHeader(title: "Modifiers", subtitle: "ಗುಣಕಗಳು")) {
      LabeledValue(
        title: "Night Multiplier",
        subtitle: "ರಾತ್ರಿ ಗುಣಕ",
        value: settingsStore.settings.nightMultiplier
      )
    }
  }
}
