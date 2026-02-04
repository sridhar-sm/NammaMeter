import Observation
import SwiftUI

struct AddCityView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState = FormState(
    input: CityFormData(name: ""),
    validator: CityFormValidator()
  )
  @State private var navigateToAddFare = false
  @State private var generatedCityId: String = ""

  private var trimmedName: String {
    formState.input.name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var canProceed: Bool {
    formState.isValid
  }

  var body: some View {
    @Bindable var formState = formState

    ZStack {
      NammaBackground()
      Form {
        Section(header: SectionHeader(title: "City Name", subtitle: "ನಗರದ ಹೆಸರು")) {
          TextField("Name", text: $formState.input.name)
            .font(FontPresets.Display.label)

          if let issue = formState.issue(for: CityFormField.name.rawValue),
             !formState.input.name.isEmpty {
            FieldErrorText(message: issue.message, severity: issue.severity)
          }
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Add City")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(isPresented: $navigateToAddFare) {
      AddFareView(cityId: generatedCityId, cityName: trimmedName, isNewCity: true)
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Next") {
          guard canProceed else { return }
          generatedCityId = "custom-\(UUID().uuidString)"
          navigateToAddFare = true
        }
        .disabled(!canProceed)
      }
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Add City")
            .font(FontPresets.Display.subhead)
          Text("ನಗರವನ್ನು ಸೇರಿಸಿ")
            .font(FontPresets.Body.small)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    AddCityView()
      .environment(SettingsStore())
  }
}
