import SwiftUI

struct SettingsWaitingChargesSection: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    Section(header: SectionHeader(title: "Waiting Charges", subtitle: "ನಿಲ್ಲಿಕೆ ಶುಲ್ಕಗಳು")) {
      LabeledValue(
        title: "Free Wait (min)",
        subtitle: "ಉಚಿತ ನಿಲ್ಲಿಕೆ (ನಿಮಿಷ)",
        value: settingsStore.settings.freeWaitMinutes
      )
      LabeledValue(
        title: "Interval (min)",
        subtitle: "ಮಧ್ಯಂತರ (ನಿಮಿಷ)",
        value: settingsStore.settings.waitIntervalMinutes
      )
      LabeledValue(
        title: "Per Interval",
        subtitle: "ಪ್ರತಿ ಮಧ್ಯಂತರ",
        value: settingsStore.settings.waitIntervalCharge
      )
    }
  }
}
