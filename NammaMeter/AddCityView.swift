import SwiftUI

struct AddCityView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(\.dismiss) private var dismiss

  @State private var name: String = ""
  @State private var baseFare: Double = 36
  @State private var perKmRate: Double = 18
  @State private var minFare: Double = 36
  @State private var includedKm: Double = 2.0
  @State private var nightMultiplier: Double = 1.5
  @State private var nightStartHour: Int = 22
  @State private var nightEndHour: Int = 5
  @State private var freeWaitMinutes: Double = 5
  @State private var waitIntervalMinutes: Double = 15
  @State private var waitIntervalCharge: Double = 10

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty
  }

  var body: some View {
    ZStack {
      NammaBackground()
      Form {
        Section(header: SectionHeader(title: "City Name", subtitle: "ನಗರದ ಹೆಸರು")) {
          TextField("Name", text: $name)
            .font(.nammaDisplay(14))
        }

        Section(header: SectionHeader(title: "Rates", subtitle: "ದರಗಳು")) {
          LabeledNumberField(
            title: "Base Fare",
            subtitle: "ಮೂಲ ಬಾಡಿಗೆ",
            value: $baseFare
          )
          LabeledNumberField(
            title: "Per Km",
            subtitle: "ಪ್ರತಿ ಕಿಲೋ ಮೀಟರ್",
            value: $perKmRate
          )
          LabeledNumberField(
            title: "Minimum Fare",
            subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ",
            value: $minFare
          )
          LabeledNumberField(
            title: "Included Km",
            subtitle: "ಸೇರಿಸಿದ ಕಿಮೀ",
            value: $includedKm
          )
        }

        Section(header: SectionHeader(title: "Waiting Charges", subtitle: "ನಿಲ್ಲಿಕೆ ಶುಲ್ಕಗಳು")) {
          LabeledNumberField(
            title: "Free Wait (min)",
            subtitle: "ಉಚಿತ ನಿಲ್ಲಿಕೆ (ನಿಮಿಷ)",
            value: $freeWaitMinutes
          )
          LabeledNumberField(
            title: "Interval (min)",
            subtitle: "ಮಧ್ಯಂತರ (ನಿಮಿಷ)",
            value: $waitIntervalMinutes
          )
          LabeledNumberField(
            title: "Per Interval",
            subtitle: "ಪ್ರತಿ ಮಧ್ಯಂತರ",
            value: $waitIntervalCharge
          )
        }

        Section(header: SectionHeader(title: "Night Fare", subtitle: "ರಾತ್ರಿ ಬಾಡಿಗೆ")) {
          LabeledNumberField(
            title: "Night Multiplier",
            subtitle: "ರಾತ್ರಿ ಗುಣಕ",
            value: $nightMultiplier
          )
          Stepper("Start Hour: \(nightStartHour):00", value: $nightStartHour, in: 0...23)
          Stepper("End Hour: \(nightEndHour):00", value: $nightEndHour, in: 0...23)
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Add City")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { save() }
          .disabled(!canSave)
      }
    }
  }

  private func save() {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else { return }

    let cityId = "custom-\(UUID().uuidString)"
    let profile = CityFareProfile(
      id: UUID().uuidString,
      cityId: cityId,
      name: trimmedName,
      cityKey: CityKey(city: trimmedName, region: nil, countryCode: "IN"),
      rates: FareRates(
        baseFare: baseFare,
        perKmRate: perKmRate,
        perMinuteRate: 0,
        includedKm: includedKm,
        minFare: minFare
      ),
      multipliers: FareMultipliers(night: nightMultiplier),
      nightWindow: NightFareWindow(startHour: nightStartHour, endHour: nightEndHour),
      waitCharges: WaitingChargePolicy(
        freeWaitMinutes: freeWaitMinutes,
        waitIntervalMinutes: waitIntervalMinutes,
        waitIntervalCharge: waitIntervalCharge
      ),
      effectiveFrom: Date()
    )

    settingsStore.addCity(profile)
    dismiss()
  }
}

#Preview {
  NavigationStack {
    AddCityView()
      .environment(SettingsStore())
  }
}
