import Observation
import SwiftUI

struct AddFareView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(\.dismiss) private var dismiss

  let cityId: String
  let cityName: String
  var isNewCity: Bool = false

  @State private var formState = FormState(
    input: FareProfileFormData(
      effectiveFrom: Date(),
      baseFare: 36,
      perKmRate: 18,
      minFare: 36,
      includedKm: 2.0,
      nightMultiplier: 1.5,
      nightStartHour: 22,
      nightEndHour: 5,
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    ),
    validator: FareProfileFormValidator()
  )

  var body: some View {
    @Bindable var formState = formState

    ZStack {
      NammaBackground()
      Form {
        Section(header: SectionHeader(title: "Effective Date", subtitle: "ಜಾರಿ ದಿನಾಂಕ")) {
          DatePicker(
            "Effective From",
            selection: $formState.input.effectiveFrom,
            displayedComponents: .date
          )
        }

        Section(header: SectionHeader(title: "Rates", subtitle: "ದರಗಳು")) {
          LabeledNumberField(
            title: "Base Fare",
            subtitle: "ಮೂಲ ಬಾಡಿಗೆ",
            value: $formState.input.baseFare
          )
          if let issue = formState.issue(for: FareProfileFormField.baseFare.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          LabeledNumberField(
            title: "Per Km",
            subtitle: "ಪ್ರತಿ ಕಿಲೋ ಮೀಟರ್",
            value: $formState.input.perKmRate
          )
          if let issue = formState.issue(for: FareProfileFormField.perKmRate.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          LabeledNumberField(
            title: "Minimum Fare",
            subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ",
            value: $formState.input.minFare
          )
          if let issue = formState.issue(for: FareProfileFormField.minFare.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          LabeledNumberField(
            title: "Included Km",
            subtitle: "ಸೇರಿಸಿದ ಕಿಮೀ",
            value: $formState.input.includedKm
          )
          if let issue = formState.issue(for: FareProfileFormField.includedKm.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }
        }

        Section(header: SectionHeader(title: "Waiting Charges", subtitle: "ನಿಲ್ಲಿಕೆ ಶುಲ್ಕಗಳು")) {
          LabeledNumberField(
            title: "Free Wait (min)",
            subtitle: "ಉಚಿತ ನಿಲ್ಲಿಕೆ (ನಿಮಿಷ)",
            value: $formState.input.freeWaitMinutes
          )
          if let issue = formState.issue(for: FareProfileFormField.freeWaitMinutes.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          LabeledNumberField(
            title: "Interval (min)",
            subtitle: "ಮಧ್ಯಂತರ (ನಿಮಿಷ)",
            value: $formState.input.waitIntervalMinutes
          )
          if let issue = formState.issue(for: FareProfileFormField.waitIntervalMinutes.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          LabeledNumberField(
            title: "Per Interval",
            subtitle: "ಪ್ರತಿ ಮಧ್ಯಂತರ",
            value: $formState.input.waitIntervalCharge
          )
          if let issue = formState.issue(for: FareProfileFormField.waitIntervalCharge.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }
        }

        Section(header: SectionHeader(title: "Night Fare", subtitle: "ರಾತ್ರಿ ಬಾಡಿಗೆ")) {
          LabeledNumberField(
            title: "Night Multiplier",
            subtitle: "ರಾತ್ರಿ ಗುಣಕ",
            value: $formState.input.nightMultiplier
          )
          if let issue = formState.issue(for: FareProfileFormField.nightMultiplier.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          Stepper(
            "Start Hour: \(formState.input.nightStartHour):00",
            value: $formState.input.nightStartHour,
            in: 0...23
          )
          if let issue = formState.issue(for: FareProfileFormField.nightStartHour.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }

          Stepper(
            "End Hour: \(formState.input.nightEndHour):00",
            value: $formState.input.nightEndHour,
            in: 0...23
          )
          if let issue = formState.issue(for: FareProfileFormField.nightEndHour.rawValue) {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Add Fare")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { save() }
          .disabled(!formState.isValid)
      }
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Add Fare")
            .font(FontPresets.Display.subhead)
          Text(cityName)
            .font(FontPresets.Body.small)
        }
      }
    }
  }

  private func save() {
    guard formState.isValid else { return }
    let input = formState.input

    let profile = CityFareProfile(
      id: UUID().uuidString,
      cityId: cityId,
      name: cityName,
      vehicleType: VehicleTypeCatalog.autoRickshaw,
      cityKey: CityKey(city: cityName, region: nil, countryCode: "IN", currencyCode: "INR"),
      rates: FareRates(
        baseFare: input.baseFare,
        perKmRate: input.perKmRate,
        perMinuteRate: 0,
        includedKm: input.includedKm,
        minFare: input.minFare
      ),
      multipliers: FareMultipliers(night: input.nightMultiplier),
      nightWindow: NightFareWindow(startHour: input.nightStartHour, endHour: input.nightEndHour),
      waitCharges: WaitingChargePolicy(
        freeWaitMinutes: input.freeWaitMinutes,
        waitIntervalMinutes: input.waitIntervalMinutes,
        waitIntervalCharge: input.waitIntervalCharge
      ),
      effectiveFrom: input.effectiveFrom
    )

    if isNewCity {
      settingsStore.addCity(profile)
    } else {
      settingsStore.addFareProfile(profile)
    }
    dismiss()
  }
}

#Preview {
  NavigationStack {
    AddFareView(cityId: "test-city", cityName: "Test City")
      .environment(AppContainer.preview)
  }
}
