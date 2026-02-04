import SwiftUI

struct MeterPagerView: View {
  @Environment(MeterStore.self) private var meterStore
  @Binding var pagerSelection: Int
  let height: CGFloat

  var body: some View {
    TabView(selection: $pagerSelection) {
      mapPage
        .tag(0)
      tripDetailsPage
        .tag(1)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .indexViewStyle(.page(backgroundDisplayMode: .always))
    .frame(height: max(height, 0))
    .background(PageSwipeDisabler().allowsHitTesting(false))
  }

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
            valueText: meterStore.fare.formatted(.currency(code: "INR").precision(.fractionLength(0))),
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
    .background(Theme.card.opacity(0.95))
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.white.opacity(0.4), lineWidth: 1)
    )
    .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
  }
}
