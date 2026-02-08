import SwiftUI

struct SettingsAppearanceSection: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    Section {
      Picker("Theme", selection: Binding(
        get: { settingsStore.themePreference },
        set: { settingsStore.themePreference = $0 }
      )) {
        Text("System").tag("system")
        Text("Light").tag("light")
        Text("Dark").tag("dark")
      }
    } header: {
      SectionHeader(title: "Appearance", subtitle: "ಪ್ರದರ್ಶನ")
    }
  }
}

#Preview {
  Form {
    SettingsAppearanceSection()
  }
  .environment(AppContainer.preview)
}
