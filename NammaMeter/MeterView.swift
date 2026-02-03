import Foundation
import MapKit
import SwiftUI
import UIKit

struct MeterView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(TripStore.self) private var tripStore
  @State private var meterStore = MeterStore()
  @Environment(\.openURL) private var openURL
  @State private var showLocationAlert = false
  @State private var showAlwaysPrompt = false
  @State private var showMeterSettings = false
  @State private var pagerSelection = 0
  @State private var meterFaceStyle: MeterFaceStyle = .superMeter
  @State private var meterRenderMode: MeterRenderMode = .full
  @State private var digitWheelStyle: DigitWheelStyle = .disk
  @State private var hasPromptedForAlways = false

  var body: some View {
    NavigationStack {
      ZStack {
        NammaBackground()
        mapArea
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .ignoresSafeArea(edges: .top)
          .padding(.bottom, 16)
      }
      .onAppear {
        meterStore.requestAuthorization()
        meterStore.refreshTimeBasedConditions()
        if meterStore.authorizationStatus == .denied || meterStore.authorizationStatus == .restricted {
          showLocationAlert = true
        }
      }
      .onChange(of: meterStore.isOnTrip) { _, isOnTrip in
        if isOnTrip {
          hasPromptedForAlways = false
          evaluateAlwaysPrompt()
        } else {
          showAlwaysPrompt = false
        }
      }
      .onChange(of: meterStore.authorizationStatus) { _, newStatus in
        if newStatus == .denied || newStatus == .restricted {
          showLocationAlert = true
        } else if newStatus == .authorizedAlways {
          showAlwaysPrompt = false
        }
        evaluateAlwaysPrompt()
      }
      .alert("Location access needed", isPresented: $showLocationAlert) {
        Button("Open Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
        Button("Not Now", role: .cancel) { }
      } message: {
        Text("Enable location to track distance and replay routes.")
      }
      .alert("Enable background tracking", isPresented: $showAlwaysPrompt) {
        Button("Enable Always") {
          meterStore.requestAlwaysAuthorization()
        }
        Button("Open Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
        Button("Not Now", role: .cancel) { }
      } message: {
        Text("Allow Always location access to keep tracking distance when the app is in the background.")
      }
      .sheet(isPresented: $showMeterSettings) {
        meterSettingsSheet
      }
    }
  }

  // MARK: - Layout

  private var mapArea: some View {
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

      // Calculate actual meter height for the selected style
      let meterNaturalHeight: CGFloat = {
        switch meterFaceStyle {
        case .superMeter:
          return SuperMeterDimensions.naturalHeight(for: geo.size.width)
        case .superElectronic:
          return SuperElectronicDimensions.naturalHeight(for: geo.size.width)
        case .goldenEagle:
          return GoldenEagleDimensions.naturalHeight(for: geo.size.width)
        case .digital:
          return SuperMeterDimensions.naturalHeight(for: geo.size.width)
        case .brightDigital:
          return BrightDigitalDimensions.naturalHeight(for: geo.size.width)
        }
      }()
      let meterHeight = min(meterNaturalHeight, maxMeterHeight)

      VStack(spacing: spacing) {
        meterPanelWithNotch(height: meterHeight, topInset: topInset)
          .frame(height: referenceMeterHeight)
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .gesture(meterStyleSwipeGesture)

        controlBar(height: controlBarHeight)
        .padding(.horizontal, 12)

        meterPager(height: fixedMapHeight)
        .padding(.horizontal, 12)
      }
      .padding(.bottom, bottomPadding)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
    }
  }

  // MARK: - Meter Panel Selection

  @ViewBuilder
  private func meterPanelWithNotch(height: CGFloat, topInset: CGFloat) -> some View {
    switch meterFaceStyle {
    case .superMeter:
      if meterRenderMode == .full {
        SuperFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          digitStyle: digitWheelStyle,
          topInset: topInset
        )
      } else {
        SuperDisplayPanel(tripState: meterStore.tripState, fare: meterStore.fare, digitStyle: digitWheelStyle)
          .padding(.top, topInset + 8)
          .padding(.horizontal, 12)
      }
    case .superElectronic:
      if meterRenderMode == .full {
        SuperElectronicFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset
        )
      } else {
        SuperElectronicFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset + 8
        )
        .padding(.horizontal, 12)
      }
    case .goldenEagle:
      if meterRenderMode == .full {
        GoldenEagleFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset
        )
      } else {
        GoldenEagleFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset + 8
        )
        .padding(.horizontal, 12)
      }
    case .digital:
      if meterRenderMode == .full {
        DigitalFullMeterPanel(tripState: meterStore.tripState, fare: meterStore.fare)
          .padding(.top, topInset + 8)
          .padding(.horizontal, 12)
      } else {
        DigitalDisplayPanel(tripState: meterStore.tripState, fare: meterStore.fare)
          .padding(.top, topInset + 8)
          .padding(.horizontal, 12)
      }
    case .brightDigital:
      if meterRenderMode == .full {
        BrightDigitalFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          topInset: topInset
        )
      } else {
        BrightDigitalFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          topInset: topInset + 8
        )
        .padding(.horizontal, 12)
      }
    }
  }

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

  // MARK: - Control Bar

  private func meterSettingsButton(metrics: ControlBarMetrics) -> some View {
    Button {
      showMeterSettings = true
    } label: {
      ControlTile(background: Theme.card.opacity(0.9), size: metrics.tileSize) {
        Image(systemName: "gauge.with.dots.needle.67percent")
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Meter settings")
  }

  private var safeAreaTop: CGFloat { windowSafeAreaInsets.top }
  private var safeAreaBottom: CGFloat { windowSafeAreaInsets.bottom }

  private func nightConditionButton(metrics: ControlBarMetrics) -> some View {
    ConditionTileButton(systemImage: "moon.stars.fill", label: "Night", isOn: bindingFor(\.isNight), isInteractive: false, metrics: metrics)
  }

  private func tripToggleButton(metrics: ControlBarMetrics) -> some View {
    Button {
      switch meterStore.tripState {
      case .forHire:
        meterStore.startTrip(settings: settingsStore.settings)
      case .inProgress:
        meterStore.stopTrip(tripStore: tripStore)
      case .complete:
        meterStore.resetToForHire()
      }
    } label: {
      MiniTripStateSign(tripState: meterStore.tripState, metrics: metrics)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tripToggleAccessibilityLabel)
  }

  private func waitToggleButton(metrics: ControlBarMetrics) -> some View {
    Button {
      meterStore.toggleWaiting()
    } label: {
      let isWaiting = meterStore.isWaiting
      ControlTile(background: (isWaiting ? Theme.coral.opacity(0.85) : Theme.card.opacity(0.9)), size: metrics.tileSize) {
        Image(systemName: isWaiting ? "play.fill" : "pause.fill")
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .disabled(!meterStore.isOnTrip)
    .opacity(meterStore.isOnTrip ? 1 : 0.6)
    .accessibilityLabel(meterStore.isWaiting ? "Resume trip" : "Pause trip")
  }

  private var tripToggleAccessibilityLabel: String {
    switch meterStore.tripState {
    case .forHire:
      return "Start trip"
    case .inProgress:
      return "Stop trip"
    case .complete:
      return "Reset trip"
    }
  }

  private func controlBar(height: CGFloat) -> some View {
    GeometryReader { geo in
      let horizontalPadding: CGFloat = 10
      let verticalPadding: CGFloat = 6
      let spacing: CGFloat = 6
      let tileCount = CGFloat(4)
      let availableWidth = max(geo.size.width - (horizontalPadding * 2), 0)
      let availableHeight = max(geo.size.height - (verticalPadding * 2), 0)
      let tileWidth = max((availableWidth - spacing * (tileCount - 1)) / tileCount, 0)
      let metrics = ControlBarMetrics(
        tileSize: CGSize(width: tileWidth, height: availableHeight),
        iconSize: min(14, max(12, tileWidth * 0.35))
      )

      HStack(spacing: spacing) {
        tripToggleButton(metrics: metrics)
        waitToggleButton(metrics: metrics)
        nightConditionButton(metrics: metrics)
        meterSettingsButton(metrics: metrics)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
    }
    .frame(height: height)
    .background(Theme.card.opacity(0.92))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: Theme.pastelShadow(), radius: 8, x: 0, y: 4)
  }

  // MARK: - Pager

  private func meterPager(height: CGFloat) -> some View {
    TabView(selection: $pagerSelection) {
      mapPage
        .tag(0)
      tripDetailsPage
        .tag(1)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .indexViewStyle(.page(backgroundDisplayMode: .always))
    .frame(height: height)
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
        let availableWidth = geo.size.width - (horizontalPadding * 2)
        let columnWidth = (availableWidth - columnSpacing) / 2
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

  // MARK: - Settings Sheet

  private var meterSettingsSheet: some View {
    NavigationStack {
      Form {
        meterSettingsSections
      }
      .navigationTitle("Meter Settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            showMeterSettings = false
          }
        }
      }
    }
  }

  @ViewBuilder
  private var meterSettingsSections: some View {
    Section("Meter Style") {
      ForEach(MeterFaceStyle.allCases) { style in
        Button {
          meterFaceStyle = style
        } label: {
          HStack {
            Label(style.label, systemImage: style.systemImage)
            Spacer()
            if meterFaceStyle == style {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.ink)
            }
          }
        }
      }
    }
    Section("Display Mode") {
      ForEach(MeterRenderMode.allCases) { mode in
        Button {
          meterRenderMode = mode
        } label: {
          HStack {
            Text(mode.label)
            Spacer()
            if meterRenderMode == mode {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.ink)
            }
          }
        }
      }
    }
    Section("Digit Style") {
      ForEach(DigitWheelStyle.allCases) { style in
        Button {
          digitWheelStyle = style
        } label: {
          HStack {
            Text(style.label)
            Spacer()
            if digitWheelStyle == style {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.ink)
            }
          }
        }
      }
    }
  }

  // MARK: - Helpers

  private func bindingFor(_ keyPath: WritableKeyPath<TripConditions, Bool>) -> Binding<Bool> {
    Binding(
      get: { meterStore.conditions[keyPath: keyPath] },
      set: { meterStore.conditions[keyPath: keyPath] = $0 }
    )
  }

  private func evaluateAlwaysPrompt() {
    guard meterStore.isOnTrip else { return }
    guard meterStore.authorizationStatus == .authorizedWhenInUse else { return }
    guard !hasPromptedForAlways else { return }
    hasPromptedForAlways = true
    showAlwaysPrompt = true
  }
}

#Preview {
  MeterView()
    .environment(SettingsStore())
    .environment(TripStore())
}
