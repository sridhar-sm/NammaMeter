import SwiftUI

struct MeterLayoutContainer: View {
  @Binding var pagerSelection: Int
  @Binding var meterFaceStyle: MeterFaceStyle
  @Binding var meterRenderMode: MeterRenderMode
  @Binding var digitWheelStyle: DigitWheelStyle
  @Binding var showMeterSettings: Bool

  var body: some View {
    GeometryReader { geo in
      let metrics = MeterLayoutMetrics(containerSize: geo.size, safeAreaTop: safeAreaTop)

      if metrics.isLandscape {
        HStack(spacing: MeterLayoutMetrics.spacing) {
          meterPanel
            .frame(width: metrics.meterSide, height: metrics.meterSide)

          VStack(spacing: MeterLayoutMetrics.spacing) {
            MeterPagerView(pagerSelection: $pagerSelection)
            MeterControlBar(height: metrics.controlBarHeight, showMeterSettings: $showMeterSettings)
          }
        }
        .padding(.top, MeterLayoutMetrics.landscapeTopPadding)
        .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
      } else {
        VStack(spacing: MeterLayoutMetrics.spacing) {
          meterPanel
            .frame(height: metrics.meterSide)
            .frame(maxWidth: .infinity)

          MeterPagerView(pagerSelection: $pagerSelection, height: metrics.fixedMapHeight)

          MeterControlBar(height: metrics.controlBarHeight, showMeterSettings: $showMeterSettings)
        }
        .padding(.top, safeAreaTop)
        .padding(.horizontal, MeterLayoutMetrics.uniformPadding)
        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
      }
    }
  }

  private var meterPanel: some View {
    MeterPanelWithNotch(
      meterFaceStyle: meterFaceStyle,
      meterRenderMode: meterRenderMode,
      digitWheelStyle: digitWheelStyle
    )
    .contentShape(Rectangle())
    .gesture(meterSwipeGesture)
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
  static let uniformPadding: CGFloat = 12
  static let landscapeTopPadding: CGFloat = 8

  let controlBarHeight: CGFloat
  let meterSide: CGFloat
  let fixedMapHeight: CGFloat
  let isLandscape: Bool

  init(containerSize: CGSize, safeAreaTop: CGFloat = 0) {
    let landscape = containerSize.width > containerSize.height
    self.isLandscape = landscape
    let controlBarHeight: CGFloat = 56
    self.controlBarHeight = controlBarHeight

    if landscape {
      // Landscape: square meter sized from available height
      let meterSide = max(containerSize.height - Self.landscapeTopPadding, 0)
      self.meterSide = meterSide
      self.fixedMapHeight = meterSide
    } else {
      // Portrait: square meter sized from available width
      let meterSide = max(containerSize.width - Self.uniformPadding * 2, 0)
      let usedHeight = safeAreaTop + meterSide + controlBarHeight + Self.spacing * 2
      let fixedMapHeight = max(containerSize.height - usedHeight, 0)
      self.meterSide = meterSide
      self.fixedMapHeight = fixedMapHeight
    }
  }
}
