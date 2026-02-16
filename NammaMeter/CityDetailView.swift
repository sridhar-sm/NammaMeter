import SwiftUI

struct CityDetailView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(MeterStore.self) private var meterStore
  let cityId: String

  private var canEditSettings: Bool {
    meterStore.tripState == .forHire
  }

  private var fareProfiles: [CityFareProfile] {
    settingsStore.fareProfiles(for: cityId)
  }

  private var cityName: String {
    fareProfiles.first?.name ?? cityId
  }

  private var vehicleTypeSections: [(vehicleType: String, profiles: [CityFareProfile])] {
    var grouped: [String: [CityFareProfile]] = [:]
    for profile in fareProfiles {
      grouped[profile.vehicleType, default: []].append(profile)
    }
    return grouped.map { (vehicleType: $0.key, profiles: $0.value.sorted { $0.effectiveFrom > $1.effectiveFrom }) }
      .sorted { VehicleTypeCatalog.displayName(for: $0.vehicleType) < VehicleTypeCatalog.displayName(for: $1.vehicleType) }
  }

  var body: some View {
    ZStack {
      NammaBackground()
      List {
        ForEach(vehicleTypeSections, id: \.vehicleType) { section in
          Section(header:
            HStack {
              Text(VehicleTypeCatalog.displayName(for: section.vehicleType))
                .font(FontPresets.Body.small)
              Spacer()
              favoriteButton(vehicleType: section.vehicleType)
            }
          ) {
            ForEach(section.profiles) { profile in
              FareCardRow(profile: profile)
            }
            .onDelete { offsets in
              deleteFareCards(offsets: offsets, in: section.profiles)
            }
          }
        }

        NavigationLink(destination: AddFareView(cityId: cityId, cityName: cityName)) {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 2) {
              Text("Add Fare Card")
                .font(FontPresets.Display.label)
              Text("ಬಾಡಿಗೆ ಕಾರ್ಡ್ ಸೇರಿಸಿ")
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
    .navigationTitle(cityName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text(cityName)
            .font(FontPresets.Display.subhead)
          Text("\(fareProfiles.count) fare card\(fareProfiles.count == 1 ? "" : "s")")
            .font(FontPresets.Body.small)
        }
      }
    }
  }

  private func favoriteButton(vehicleType: String) -> some View {
    let favorite = WhatIfFavorite(cityId: cityId, vehicleType: vehicleType)
    let isFavorited = settingsStore.whatIfFavorites.contains { $0.id == favorite.id }
    let atCapacity = settingsStore.whatIfFavorites.count >= 3

    return Button {
      if isFavorited {
        settingsStore.removeWhatIfFavorite(favorite)
      } else {
        settingsStore.addWhatIfFavorite(favorite)
      }
    } label: {
      Image(systemName: isFavorited ? "star.fill" : "star")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(isFavorited ? Color.orange : Theme.ink.opacity(0.3))
    }
    .buttonStyle(.plain)
    .disabled(!isFavorited && atCapacity)
    .opacity(!isFavorited && atCapacity ? 0.3 : 1)
    .accessibilityLabel(isFavorited ? "Remove from WhatIf favorites" : "Add to WhatIf favorites")
  }

  private func deleteFareCards(offsets: IndexSet, in profiles: [CityFareProfile]) {
    guard canEditSettings else { return }
    for offset in offsets {
      settingsStore.deleteFareProfile(profiles[offset].id)
    }
  }
}

struct FareCardRow: View {
  let profile: CityFareProfile

  private var currencySymbol: String {
    switch profile.cityKey.currencyCode {
    case "INR": return "₹"
    case "USD": return "$"
    case "GBP": return "£"
    default: return profile.cityKey.currencyCode + " "
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Effective: \(profile.effectiveFrom.formatted(date: .abbreviated, time: .omitted))")
        .font(FontPresets.Body.small)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 12) {
          FareDetail(label: "Base", value: profile.rates.baseFare, currencySymbol: currencySymbol)
          FareDetail(label: "Per Km", value: profile.rates.perKmRate, currencySymbol: currencySymbol)
          FareDetail(label: "Min", value: profile.rates.minFare, currencySymbol: currencySymbol)
        }

        HStack(spacing: 12) {
          FareDetail(label: "Free Wait", value: profile.waitCharges.freeWaitMinutes, unit: "min", isCurrency: false)
          FareDetail(label: "Interval", value: profile.waitCharges.waitIntervalMinutes, unit: "min", isCurrency: false)
          FareDetail(label: "Per Int.", value: profile.waitCharges.waitIntervalCharge, currencySymbol: currencySymbol)
        }

        HStack(spacing: 12) {
          FareDetail(label: "Night ×", value: profile.multipliers.night, isCurrency: false)
          Text("(\(profile.nightWindow.startHour):00 - \(profile.nightWindow.endHour):00)")
            .font(FontPresets.Body.xSmall)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

struct FareDetail: View {
  let label: String
  let value: Double
  var unit: String? = nil
  var isCurrency: Bool = true
  var currencySymbol: String = "₹"

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(label)
        .font(FontPresets.Body.micro)
        .foregroundStyle(.tertiary)
      if isCurrency {
        Text("\(currencySymbol)\(value, specifier: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f")\(unit ?? "")")
          .font(FontPresets.Body.base)
      } else {
        Text("\(value, specifier: "%.1f")\(unit ?? "")")
          .font(FontPresets.Body.base)
      }
    }
  }
}

#Preview {
  NavigationStack {
    CityDetailView(cityId: "bengaluru")
      .environment(AppContainer.preview)
  }
}
