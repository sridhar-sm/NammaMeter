import SwiftUI

struct CityManagementView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(MeterStore.self) private var meterStore
  @State private var cityToDelete: CityFareProfile?
  @State private var showDeleteConfirmation = false

  private var canEditSettings: Bool {
    meterStore.tripState == .forHire
  }

  var body: some View {
    ZStack {
      NammaBackground()
      List {
        ForEach(settingsStore.availableCities) { city in
          NavigationLink(destination: CityDetailView(cityId: city.cityId)) {
            CityRow(city: city, isSelected: settingsStore.selectedCityId == city.cityId)
          }
        }
        .onDelete(perform: deleteCities)

        NavigationLink(destination: AddCityView()) {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 2) {
              Text("Add City")
                .font(FontPresets.Display.label)
              Text("ನಗರವನ್ನು ಸೇರಿಸಿ")
                .font(FontPresets.Body.small)
                .foregroundStyle(.secondary)
            }
          }
        }
        .disabled(!canEditSettings)
        .opacity(canEditSettings ? 1 : 0.5)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Manage Cities")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Manage Cities")
            .font(FontPresets.Display.subhead)
          Text("ನಗರಗಳನ್ನು ನಿರ್ವಹಿಸಿ")
            .font(FontPresets.Body.small)
        }
      }
    }
    .alert("Delete City?", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {
        cityToDelete = nil
      }
      Button("Delete", role: .destructive) {
        if let city = cityToDelete {
          settingsStore.deleteCity(city.cityId)
        }
        cityToDelete = nil
      }
    } message: {
      if let city = cityToDelete {
        let count = settingsStore.fareProfiles(for: city.cityId).count
        Text("This will delete \(city.name) and its \(count) fare card\(count == 1 ? "" : "s").")
      }
    }
  }

  private func deleteCities(at offsets: IndexSet) {
    guard canEditSettings else { return }
    for offset in offsets {
      let city = settingsStore.availableCities[offset]
      let fareCount = settingsStore.fareProfiles(for: city.cityId).count
      if fareCount > 0 {
        cityToDelete = city
        showDeleteConfirmation = true
      } else {
        settingsStore.deleteCity(city.cityId)
      }
    }
  }
}

struct CityRow: View {
  let city: CityFareProfile
  let isSelected: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(city.name)
          .font(FontPresets.Display.label)
        if let region = city.cityKey.region {
          Text(region)
            .font(FontPresets.Body.small)
            .foregroundStyle(.secondary)
        }
        HStack(spacing: 8) {
          Text("Base: ₹\(city.rates.baseFare, specifier: "%.0f")")
          Text("Per Km: ₹\(city.rates.perKmRate, specifier: "%.0f")")
        }
        .font(FontPresets.Body.xSmall)
        .foregroundStyle(.secondary)
      }
      Spacer()
      if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Theme.ink)
      }
    }
  }
}

#Preview {
  NavigationStack {
    CityManagementView()
      .environment(AppContainer.preview)
  }
}
