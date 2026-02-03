import Observation
import SwiftUI

struct SettingsView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(MeterStore.self) private var meterStore

  private var canEditSettings: Bool {
    meterStore.tripState == .forHire
  }

  var body: some View {
    @Bindable var settingsStore = settingsStore
    NavigationStack {
      ZStack {
        NammaBackground()
        Form {
          Section {
            VStack(alignment: .leading, spacing: 6) {
              Text("Meter Settings")
                .font(.nammaDisplay(20))
              Text("ಮೀಟರ್ ಸೆಟ್ಟಿಂಗ್ಸ್")
                .font(.nammaBody(13))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
          }

          Section(header: SectionHeader(title: "City", subtitle: "ನಗರ")) {
            ForEach(settingsStore.availableCities) { city in
              Button {
                settingsStore.selectCity(city.cityId)
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                      .font(.nammaDisplay(14))
                    if let region = city.cityKey.region {
                      Text(region)
                        .font(.nammaBody(11))
                        .foregroundStyle(.secondary)
                    }
                  }
                  Spacer()
                  if settingsStore.selectedCityId == city.cityId {
                    Image(systemName: "checkmark")
                      .foregroundStyle(Theme.ink)
                  }
                }
              }
              .buttonStyle(.plain)
              .disabled(!canEditSettings)
              .opacity(canEditSettings ? 1 : 0.5)
            }

            NavigationLink(destination: AddCityView()) {
              HStack {
                Image(systemName: "plus.circle.fill")
                  .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 2) {
                  Text("Add City")
                    .font(.nammaDisplay(14))
                  Text("ನಗರವನ್ನು ಸೇರಿಸಿ")
                    .font(.nammaBody(11))
                    .foregroundStyle(.secondary)
                }
              }
            }
            .disabled(!canEditSettings)
            .opacity(canEditSettings ? 1 : 0.5)
          }

          Section(header: SectionHeader(title: "Rates", subtitle: "ದರಗಳು")) {
            LabeledNumberField(
              title: "Base Fare",
              subtitle: "ಮೂಲ ಬಾಡಿಗೆ",
              value: $settingsStore.settings.baseFare
            )
            LabeledNumberField(
              title: "Per Km",
              subtitle: "ಪ್ರತಿ ಕಿಲೋ ಮೀಟರ್",
              value: $settingsStore.settings.perKmRate
            )
            LabeledNumberField(
              title: "Minimum Fare",
              subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ",
              value: $settingsStore.settings.minFare
            )
          }

          Section(header: SectionHeader(title: "Waiting Charges", subtitle: "ನಿಲ್ಲಿಕೆ ಶುಲ್ಕಗಳು")) {
            LabeledNumberField(
              title: "Free Wait (min)",
              subtitle: "ಉಚಿತ ನಿಲ್ಲಿಕೆ (ನಿಮಿಷ)",
              value: $settingsStore.settings.freeWaitMinutes
            )
            LabeledNumberField(
              title: "Interval (min)",
              subtitle: "ಮಧ್ಯಂತರ (ನಿಮಿಷ)",
              value: $settingsStore.settings.waitIntervalMinutes
            )
            LabeledNumberField(
              title: "Per Interval",
              subtitle: "ಪ್ರತಿ ಮಧ್ಯಂತರ",
              value: $settingsStore.settings.waitIntervalCharge
            )
          }

          Section(header: SectionHeader(title: "Modifiers", subtitle: "ಗುಣಕಗಳು")) {
            LabeledNumberField(
              title: "Night Multiplier",
              subtitle: "ರಾತ್ರಿ ಗುಣಕ",
              value: $settingsStore.settings.nightMultiplier
            )
          }

          Section {
            Button {
              settingsStore.resetToDefaults()
            } label: {
              Text("Reset to defaults")
            }
          }
        }
        .scrollContentBackground(.hidden)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack(spacing: 2) {
            Text("Settings")
              .font(.nammaDisplay(16))
            Text("ಸೆಟ್ಟಿಂಗ್ಸ್")
              .font(.nammaBody(11))
          }
        }
      }
    }
  }
}

struct SectionHeader: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.nammaDisplay(14))
      Text(subtitle)
        .font(.nammaBody(11))
        .foregroundStyle(.secondary)
    }
    .textCase(nil)
  }
}

struct LabeledNumberField: View {
  let title: String
  let subtitle: String
  @Binding var value: Double

  var body: some View {
    LabeledContent {
      TextField("", value: $value, format: .number.precision(.fractionLength(2)))
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
    } label: {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text(subtitle)
          .font(.nammaBody(11))
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  SettingsView()
    .environment(SettingsStore())
    .environment(MeterStore())
}
