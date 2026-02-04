import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      ZStack {
        NammaBackground()
        Form {
          Section {
            SettingsHeader()
          }

          SettingsCitySection()
          SettingsRatesSection()
          SettingsWaitingChargesSection()
          SettingsModifiersSection()
          SettingsResetSection()
        }
        .scrollContentBackground(.hidden)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack(spacing: 2) {
            Text("Settings")
              .font(FontPresets.Display.subhead)
            Text("ಸೆಟ್ಟಿಂಗ್ಸ್")
              .font(FontPresets.Body.small)
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
        .font(FontPresets.Display.label)
      Text(subtitle)
        .font(FontPresets.Body.small)
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
          .font(FontPresets.Body.small)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct LabeledValue: View {
  let title: String
  let subtitle: String
  let value: Double

  var body: some View {
    LabeledContent {
      Text(value, format: .number.precision(.fractionLength(2)))
        .foregroundStyle(.secondary)
    } label: {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text(subtitle)
          .font(FontPresets.Body.small)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  SettingsView()
    .environment(SettingsStore())
    .environment(MeterStore())
    .previewDevice("iPhone 17 Pro")
}
