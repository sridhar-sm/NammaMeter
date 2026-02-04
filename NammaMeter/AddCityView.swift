import SwiftUI

struct AddCityView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var name: String = ""
  @State private var navigateToAddFare = false
  @State private var generatedCityId: String = ""

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespaces)
  }

  private var canProceed: Bool {
    !trimmedName.isEmpty
  }

  var body: some View {
    ZStack {
      NammaBackground()
      Form {
        Section(header: SectionHeader(title: "City Name", subtitle: "ನಗರದ ಹೆಸರು")) {
          TextField("Name", text: $name)
            .font(FontPresets.Display.label)
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
