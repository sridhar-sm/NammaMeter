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

    Section(header: SectionHeader(title: "Display", subtitle: "ಪ್ರದರ್ಶನ")) {
      Toggle(isOn: Binding(
        get: { settingsStore.settings.keepScreenAwakeDuringTrip },
        set: { settingsStore.settings.keepScreenAwakeDuringTrip = $0 }
      )) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Keep Screen Awake")
          Text("During Active Trip")
            .font(FontPresets.Body.small)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
