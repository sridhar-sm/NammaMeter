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
      let bottomPadding: CGFloat = 8
      let spacing: CGFloat = 4
      let minMapHeight: CGFloat = 100
      let controlBarHeight = min(max(geo.size.height * 0.085, 56), 72)

      // Available height after accounting for all fixed elements
      let availableHeight = geo.size.height - bottomPadding - controlBarHeight - (spacing * 2)

      // Use the largest meter height (Super Mechanical) to determine fixed map height
      // This ensures map size and position stay constant regardless of meter style
      let maxMeterNaturalHeight = SuperMeterDimensions.naturalHeight(for: geo.size.width)
      let maxMeterHeight = availableHeight - minMapHeight
      let referenceMeterHeight = min(maxMeterNaturalHeight, maxMeterHeight)
      let fixedMapHeight = availableHeight - referenceMeterHeight

      VStack(spacing: spacing) {
        MeterPanelWithNotch(
          meterFaceStyle: meterFaceStyle,
          meterRenderMode: meterRenderMode,
          digitWheelStyle: digitWheelStyle,
          topInset: topInset
        )
        .frame(height: referenceMeterHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(meterStyleSwipeGesture)

        MeterControlBar(height: controlBarHeight, showMeterSettings: $showMeterSettings)
          .padding(.horizontal, 12)

        MeterPagerView(pagerSelection: $pagerSelection, height: fixedMapHeight)
          .padding(.horizontal, 12)
      }
      .padding(.bottom, bottomPadding)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
    }
  }

  private var safeAreaTop: CGFloat { windowSafeAreaInsets.top }

  private var meterStyleSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 24, coordinateSpace: .local)
      .onEnded { value in
        let horizontal = value.translation.width
        let vertical = value.translation.height
        guard abs(horizontal) > abs(vertical) else { return }
        guard abs(horizontal) > 32 else { return }
        advanceMeterStyle(by: horizontal < 0 ? 1 : -1)
      }
  }

  private func advanceMeterStyle(by offset: Int) {
    let styles = MeterFaceStyle.allCases
    guard let currentIndex = styles.firstIndex(of: meterFaceStyle) else { return }
    let nextIndex = (currentIndex + offset + styles.count) % styles.count
    meterFaceStyle = styles[nextIndex]
  }
}
