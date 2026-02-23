import SwiftUI

struct WatchFavoritesView: View {
  @Environment(WatchTripStore.self) private var tripStore

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        Text("Favorites")
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)

        if tripStore.tripState == .inProgress {
          // Show WhatIf comparison fares during active trip
          whatIfResults
        } else {
          // Show favorite city/vehicle names when idle
          favoriteSummaries
        }
      }
      .padding(.horizontal, 4)
    }
  }

  @ViewBuilder
  private var whatIfResults: some View {
    if tripStore.whatIfResults.isEmpty {
      Text("No favorites")
        .font(.system(size: 13))
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    } else {
      ForEach(tripStore.whatIfResults, id: \.id) { result in
        VStack(alignment: .leading, spacing: 2) {
          Text(result.cityName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)

          HStack {
            Text(result.vehicleDisplayName)
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
            Spacer()
            Text(formatCurrency(result.fare, code: result.currencyCode))
              .font(.system(size: 13, weight: .bold, design: .monospaced))
              .foregroundStyle(.green)
          }
        }
        .padding(6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }

  @ViewBuilder
  private var favoriteSummaries: some View {
    if let favorites = tripStore.config?.whatIfFavorites, !favorites.isEmpty {
      ForEach(favorites, id: \.id) { fav in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(fav.cityName)
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(.white)
              .lineLimit(1)
            Text(fav.vehicleDisplayName)
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .padding(6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    } else {
      Text("No favorites")
        .font(.system(size: 13))
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
  }
}
