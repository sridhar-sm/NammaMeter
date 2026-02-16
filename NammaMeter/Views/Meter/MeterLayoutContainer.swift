import SwiftUI

struct MeterLayoutContainer: View {
  @Binding var pagerSelection: Int
  @Binding var meterFaceStyle: MeterFaceStyle
  @Binding var meterRenderMode: MeterRenderMode
  @Binding var digitWheelStyle: DigitWheelStyle
  @Binding var showMeterSettings: Bool

  var body: some View {
    GeometryReader { geo in
      let topInset = safeAreaTop
      let bottomPadding = MeterLayoutMetrics.bottomPadding
      let spacing = MeterLayoutMetrics.spacing
      let metrics = MeterLayoutMetrics(containerSize: geo.size)

      VStack(spacing: spacing) {
        MeterPanelWithNotch(
          meterFaceStyle: meterFaceStyle,
          meterRenderMode: meterRenderMode,
          digitWheelStyle: digitWheelStyle,
          topInset: topInset
        )
        .frame(height: metrics.referenceMeterHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(meterSwipeGesture)

        MeterControlBar(height: metrics.controlBarHeight, showMeterSettings: $showMeterSettings)
          .padding(.horizontal, 12)

        MeterPagerView(pagerSelection: $pagerSelection, height: metrics.fixedMapHeight)
          .padding(.horizontal, 12)
      }
      .padding(.bottom, bottomPadding)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
    }
  }

  private var safeAreaTop: CGFloat { windowSafeAreaInsets.top }

  private var meterSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 24, coordinateSpace: .local)
      .onEnded { value in
        let horizontal = value.translation.width
        let vertical = value.translation.height
        if abs(horizontal) > abs(vertical) && abs(horizontal) > 32 {
          advanceMeterStyle(by: horizontal < 0 ? 1 : -1)
        }
      }
  }

  private func advanceMeterStyle(by offset: Int) {
    let styles = MeterFaceStyle.allCases
    guard let currentIndex = styles.firstIndex(of: meterFaceStyle) else { return }
    let nextIndex = (currentIndex + offset + styles.count) % styles.count
    meterFaceStyle = styles[nextIndex]
  }

}

struct MeterLayoutMetrics: Equatable {
  static let bottomPadding: CGFloat = 8
  static let spacing: CGFloat = 4
  static let minMapHeight: CGFloat = 100

  let controlBarHeight: CGFloat
  let referenceMeterHeight: CGFloat
  let fixedMapHeight: CGFloat
  let availableHeight: CGFloat

  init(containerSize: CGSize) {
    let controlBarHeight: CGFloat = 56  // Fixed height with 48pt buttons + 4pt padding

    let rawAvailableHeight = containerSize.height - Self.bottomPadding - controlBarHeight - (Self.spacing * 2)
    let availableHeight = max(rawAvailableHeight, 0)

    let maxMeterNaturalHeight = SuperMeterDimensions.naturalHeight(for: containerSize.width)
    let maxAllowedMeterHeight = containerSize.height * 0.65

    let cappedMeterHeight: CGFloat
    if maxMeterNaturalHeight > maxAllowedMeterHeight {
      // Meter exceeds 65%, clamp it
      cappedMeterHeight = maxAllowedMeterHeight
    } else {
      // Meter fits within 65%
      cappedMeterHeight = maxMeterNaturalHeight
    }

    let maxMeterHeight = max(availableHeight - Self.minMapHeight, 0)
    let referenceMeterHeight = max(min(cappedMeterHeight, maxMeterHeight), 0)
    let fixedMapHeight = max(availableHeight - referenceMeterHeight, 0)

    self.controlBarHeight = controlBarHeight
    self.referenceMeterHeight = referenceMeterHeight
    self.fixedMapHeight = fixedMapHeight
    self.availableHeight = availableHeight
  }
}
