import SwiftUI

struct SettingsRatesSection: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    Section(header: SectionHeader(title: "Rates", subtitle: "ದರಗಳು")) {
      LabeledValue(
        title: "Base Fare",
        subtitle: "ಮೂಲ ಬಾಡಿಗೆ",
        value: settingsStore.settings.baseFare
      )
      LabeledValue(
        title: "Per Km",
        subtitle: "ಪ್ರತಿ ಕಿಲೋ ಮೀಟರ್",
        value: settingsStore.settings.perKmRate
      )
      LabeledValue(
        title: "Minimum Fare",
        subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ",
        value: settingsStore.settings.minFare
      )
    }
  }
}
