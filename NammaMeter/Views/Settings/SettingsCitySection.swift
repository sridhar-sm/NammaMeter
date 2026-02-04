import SwiftUI

struct SettingsCitySection: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(MeterStore.self) private var meterStore

  private var canEditSettings: Bool {
    meterStore.tripState == .forHire
  }

  var body: some View {
    Section(header: SectionHeader(title: "City", subtitle: "ನಗರ")) {
      Picker("City", selection: Binding(
        get: { settingsStore.selectedCityId ?? "" },
        set: { settingsStore.selectCity($0) }
      )) {
        ForEach(settingsStore.availableCities) { city in
          Text(city.name).tag(city.cityId)
        }
      }
      .pickerStyle(.menu)
      .disabled(!canEditSettings)

      NavigationLink(destination: CityManagementView()) {
        HStack {
          Image(systemName: "building.2")
            .foregroundStyle(Theme.ink)
          VStack(alignment: .leading, spacing: 2) {
            Text("Manage Cities")
              .font(FontPresets.Display.label)
            Text("ನಗರಗಳನ್ನು ನಿರ್ವಹಿಸಿ")
              .font(FontPresets.Body.small)
              .foregroundStyle(.secondary)
          }
        }
      }
      .disabled(!canEditSettings)
      .opacity(canEditSettings ? 1 : 0.5)
    }
  }
}
