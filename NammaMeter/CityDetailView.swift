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

  var body: some View {
    ZStack {
      NammaBackground()
      List {
        ForEach(fareProfiles) { profile in
          FareCardRow(profile: profile)
        }
        .onDelete(perform: deleteFareCards)

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

  private func deleteFareCards(at offsets: IndexSet) {
    guard canEditSettings else { return }
    for offset in offsets {
      settingsStore.deleteFareProfile(fareProfiles[offset].id)
    }
  }
}

struct FareCardRow: View {
  let profile: CityFareProfile

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Effective: \(profile.effectiveFrom.formatted(date: .abbreviated, time: .omitted))")
        .font(FontPresets.Body.small)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 12) {
          FareDetail(label: "Base", value: profile.rates.baseFare)
          FareDetail(label: "Per Km", value: profile.rates.perKmRate)
          FareDetail(label: "Min", value: profile.rates.minFare)
        }

        HStack(spacing: 12) {
          FareDetail(label: "Free Wait", value: profile.waitCharges.freeWaitMinutes, unit: "min")
          FareDetail(label: "Interval", value: profile.waitCharges.waitIntervalMinutes, unit: "min")
          FareDetail(label: "Per Int.", value: profile.waitCharges.waitIntervalCharge)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(label)
        .font(FontPresets.Body.micro)
        .foregroundStyle(.tertiary)
      if isCurrency {
        Text("₹\(value, specifier: "%.0f")\(unit ?? "")")
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
      .environment(SettingsStore())
      .environment(MeterStore())
  }
}
