import SwiftUI

struct MeterPagerView: View {
  @Environment(MeterStore.self) private var meterStore
  @Environment(SettingsStore.self) private var settingsStore
  @Binding var pagerSelection: Int
  var height: CGFloat? = nil

  var body: some View {
    GeometryReader { geo in
      TabView(selection: $pagerSelection) {
        mapPage
          .tag(0)

        if meterStore.tripState == .forHire {
          ForEach(Array(forHirePages.enumerated()), id: \.element.id) { index, item in
            meterPageContainer {
              FareRulesPreviewPage(profile: item.profile)
            }
            .tag(1 + index)
          }
        } else {
          tripDetailsPage
            .tag(1)
          ForEach(Array(meterStore.whatIfResults.enumerated()), id: \.element.favorite.id) { index, result in
            meterPageContainer {
              WhatIfComparisonPage(
                result: result,
                primaryFare: meterStore.fare,
                primaryCurrencyCode: meterStore.activeCurrencyCode
              )
            }
            .tag(2 + index)
          }
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .background(PageSwipeDisabler().allowsHitTesting(false))
      .onChange(of: pageCount) { _, newCount in
        if pagerSelection >= newCount {
          pagerSelection = min(1, newCount - 1)
        }
      }
      .onChange(of: meterStore.tripState) { _, _ in
        if pagerSelection > 1 {
          pagerSelection = 1
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .contentShape(Rectangle())
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.white.opacity(0.4), lineWidth: 1)
    )
    .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
  }

  // MARK: - ForHire Pages

  private var forHirePages: [ForHirePageItem] {
    var pages: [ForHirePageItem] = []
    if let profile = settingsStore.activeProfileForCurrentSelection {
      pages.append(ForHirePageItem(id: "current", profile: profile))
    }
    for fav in settingsStore.whatIfFavorites {
      if let profile = settingsStore.whatIfProfile(for: fav) {
        pages.append(ForHirePageItem(id: fav.id, profile: profile))
      }
    }
    return pages
  }

  private var pageCount: Int {
    if meterStore.tripState == .forHire {
      return 1 + forHirePages.count
    } else {
      return 2 + meterStore.whatIfResults.count
    }
  }

  // MARK: - Trip Pages

  private var mapPage: some View {
    meterPageContainer {
      LiveRouteMap(points: meterStore.points, followLatest: meterStore.isOnTrip)
    }
  }

  private var tripDetailsPage: some View {
    meterPageContainer {
      GeometryReader { geo in
        let horizontalPadding: CGFloat = 12
        let columnSpacing: CGFloat = 12
        let availableWidth = max(geo.size.width - (horizontalPadding * 2), 0)
        let columnWidth = max((availableWidth - columnSpacing) / 2, 0)
        let tileHeight: CGFloat = 52

        let detailItems: [(String, String)] = [
          ((meterStore.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2))) + " km", "Distance · ದೂರ"),
          (formattedElapsed(meterStore.elapsed), "Time · ಸಮಯ"),
          (formattedElapsed(meterStore.waitingDuration), "Wait · ನಿಲ್ಲಿಕೆ"),
          (meterStore.currentSpeedKph.formatted(.number.precision(.fractionLength(1))) + " km/h", "Speed · ವೇಗ")
        ]

        VStack(spacing: 12) {
          FareInfoTile(
            valueText: meterStore.fare.formatted(.currency(code: meterStore.activeCurrencyCode).precision(.fractionLength(meterStore.activeCurrencyCode == "INR" ? 0 : 2))),
            labelText: "Fare · ಭಾಡೆ",
            size: CGSize(width: availableWidth, height: 56),
            showsChevron: false,
            isExpanded: false
          )

          LazyVGrid(
            columns: [
              GridItem(.fixed(columnWidth), spacing: columnSpacing),
              GridItem(.fixed(columnWidth), spacing: columnSpacing)
            ],
            spacing: columnSpacing
          ) {
            ForEach(detailItems.indices, id: \.self) { index in
              FareInfoTile(
                valueText: detailItems[index].0,
                labelText: detailItems[index].1,
                size: CGSize(width: columnWidth, height: tileHeight),
                showsChevron: false,
                isExpanded: false
              )
            }
          }

          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
      }
    }
  }

  private func meterPageContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.card.opacity(0.95))
  }
}

// MARK: - Supporting Types

private struct ForHirePageItem: Identifiable {
  let id: String
  let profile: CityFareProfile
}
