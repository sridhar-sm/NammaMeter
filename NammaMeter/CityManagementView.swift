import SwiftUI

struct CityManagementView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(MeterStore.self) private var meterStore
  @State private var cityToDelete: CityGroup?
  @State private var showDeleteConfirmation = false

  private var canEditSettings: Bool {
    meterStore.tripState == .forHire
  }

  var body: some View {
    ZStack {
      NammaBackground()
      List {
        ForEach(settingsStore.availableCityGroups) { group in
          NavigationLink(destination: CityDetailView(cityId: group.cityId)) {
            CityRow(
              group: group,
              isSelected: settingsStore.selectedCityId == group.cityId,
              hasFavorite: settingsStore.whatIfFavorites.contains { $0.cityId == group.cityId }
            )
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
          if settingsStore.whatIfFavorites.isEmpty {
            Text("ನಗರಗಳನ್ನು ನಿರ್ವಹಿಸಿ")
              .font(FontPresets.Body.small)
          } else {
            Text("\(settingsStore.whatIfFavorites.count)/3 WhatIf favorites")
              .font(FontPresets.Body.small)
          }
        }
      }
    }
    .alert("Delete City?", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {
        cityToDelete = nil
      }
      Button("Delete", role: .destructive) {
        if let group = cityToDelete {
          settingsStore.deleteCity(group.cityId)
        }
        cityToDelete = nil
      }
    } message: {
      if let group = cityToDelete {
        let count = settingsStore.fareProfiles(for: group.cityId).count
        Text("This will delete \(group.name) and its \(count) fare card\(count == 1 ? "" : "s").")
      }
    }
  }

  private func deleteCities(at offsets: IndexSet) {
    guard canEditSettings else { return }
    for offset in offsets {
      let group = settingsStore.availableCityGroups[offset]
      let fareCount = settingsStore.fareProfiles(for: group.cityId).count
      if fareCount > 0 {
        cityToDelete = group
        showDeleteConfirmation = true
      } else {
        settingsStore.deleteCity(group.cityId)
      }
    }
  }
}

struct CityRow: View {
  let group: CityGroup
  let isSelected: Bool
  var hasFavorite: Bool = false

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(group.name)
            .font(FontPresets.Display.label)
          if hasFavorite {
            Image(systemName: "star.fill")
              .font(.system(size: 10))
              .foregroundStyle(Theme.mango)
          }
        }
        if let region = group.cityKey.region {
          Text(region)
            .font(FontPresets.Body.small)
            .foregroundStyle(.secondary)
        }
        Text("\(group.vehicleTypes.count) vehicle type\(group.vehicleTypes.count == 1 ? "" : "s")")
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
