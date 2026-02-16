import SwiftUI

struct TripComparisonView: View {
  let trip: Trip

  @Environment(SettingsStore.self) private var settingsStore
  @Environment(ExchangeRateProvider.self) private var exchangeRateProvider
  @State private var results: [WhatIfResult] = []
  @State private var expandedResultId: String?

  private var primaryCurrencyCode: String {
    trip.rateSnapshot.currencyCode ?? "INR"
  }

  var body: some View {
    ZStack {
      NammaBackground()
      ScrollView {
        VStack(spacing: 20) {
          yourTripCard
          if results.isEmpty {
            emptyState
          } else {
            ForEach(results, id: \.favorite.id) { result in
              comparisonCard(for: result)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("WhatIf Compare")
            .font(FontPresets.Display.subhead)
          Text("ಹೋಲಿಕೆ")
            .font(FontPresets.Body.small)
        }
      }
    }
    .onAppear { calculateComparisons() }
  }

  private var yourTripCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Your Trip")
            .font(FontPresets.Display.subhead)
          if let cityName = trip.rateSnapshot.cityName {
            HStack(spacing: 4) {
              Text(cityName)
              if let vt = trip.rateSnapshot.vehicleType {
                Text("·")
                Text(VehicleTypeCatalog.displayName(for: vt))
              }
            }
            .font(FontPresets.Body.base)
            .foregroundStyle(Theme.ink.opacity(0.7))
          }
        }
        Spacer()
      }

      HStack(spacing: 12) {
        SummaryChip(title: "Fare", value: formatCurrency(trip.fare, code: primaryCurrencyCode))
        SummaryChip(title: "Distance", value: "\((trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2)))) km")
        SummaryChip(title: "Time", value: formattedElapsed(trip.duration))
      }
    }
    .cardStyle()
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Text("No WhatIf favorites set")
        .font(FontPresets.Display.subhead)
        .foregroundStyle(Theme.ink)
      Text("Add favorites in City Management to compare fares")
        .font(FontPresets.Body.small)
        .foregroundStyle(Theme.ink.opacity(0.7))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 80)
    .cardStyle()
  }

  private func comparisonCard(for result: WhatIfResult) -> some View {
    let isExpanded = expandedResultId == result.favorite.id
    let isForeign = result.currencyCode != primaryCurrencyCode

    let displayFare: String = {
      if isExpanded || !isForeign {
        return formatCurrency(result.fareInNativeCurrency, code: result.currencyCode)
      }
      let converted = convertToPrimary(result.fareInNativeCurrency, from: result.currencyCode)
      return formatCurrency(converted, code: primaryCurrencyCode)
    }()

    let whatIfInPrimary = isForeign
      ? convertToPrimary(result.fareInNativeCurrency, from: result.currencyCode)
      : result.fareInNativeCurrency
    let diff = whatIfInPrimary - trip.fare
    let sign = diff >= 0 ? "+" : ""
    let diffText = "\(sign)\(formatCurrency(abs(diff), code: primaryCurrencyCode))"

    return VStack(alignment: .leading, spacing: 10) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(result.cityName)
            .font(FontPresets.Display.subhead)
          Text(VehicleTypeCatalog.displayName(for: result.vehicleType))
            .font(FontPresets.Body.small)
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          Text(displayFare)
            .font(FontPresets.Display.label)
          if isExpanded {
            Text(result.currencyCode)
              .font(FontPresets.Body.xSmall)
              .foregroundStyle(Theme.ink.opacity(0.5))
          }
        }
      }

      HStack {
        Text(diffText)
          .font(FontPresets.Display.detail)
          .foregroundStyle(diff >= 0 ? Theme.coral : Theme.mint)
        Text("vs your fare")
          .font(FontPresets.Body.small)
          .foregroundStyle(Theme.ink.opacity(0.5))
        Spacer()
        if isForeign {
          Image(systemName: isExpanded ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
            .font(.system(size: 14))
            .foregroundStyle(Theme.ink.opacity(0.4))
        }
      }
    }
    .cardStyle()
    .onTapGesture {
      guard isForeign else { return }
      withAnimation(.easeInOut(duration: 0.2)) {
        expandedResultId = isExpanded ? nil : result.favorite.id
      }
    }
  }

  private func convertToPrimary(_ amount: Double, from code: String) -> Double {
    exchangeRateProvider.convert(amount, from: code, to: primaryCurrencyCode) ?? amount
  }

  private func calculateComparisons() {
    let favorites = settingsStore.whatIfFavorites
    results = WhatIfCalculator.calculateAll(
      favorites: favorites,
      profileLookup: { settingsStore.whatIfProfile(for: $0) },
      distanceKm: trip.distanceMeters / 1000,
      elapsedTime: trip.duration,
      waitingTime: trip.waitingDuration,
      tripDate: trip.startDate,
      isNight: trip.conditions.isNight
    )
  }
}
