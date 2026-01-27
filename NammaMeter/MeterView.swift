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
  @State private var showMeterPanel = false
  @State private var meterFaceStyle: MeterFaceStyle = .superMeter
  @State private var meterRenderMode: MeterRenderMode = .full
  @State private var digitWheelStyle: DigitWheelStyle = .disk
  private let fareTileSize = CGSize(width: 124, height: 50)
  private let fareTileSpacing: CGFloat = 6

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
      .onChange(of: meterStore.authorizationStatus) { _, newStatus in
        if newStatus == .denied || newStatus == .restricted {
          showLocationAlert = true
        }
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
    }
  }

  private var mapArea: some View {
    GeometryReader { geo in
      let minMapHeight: CGFloat = 160
      let actionBarHeight = max(safeAreaBottom + 56, 72)
      let desiredMeterHeight = max(geo.size.height * 0.55, 320)
      let maxMeterHeight = max(geo.size.height - minMapHeight - actionBarHeight - 24, 0)
      let meterHeight = min(desiredMeterHeight, maxMeterHeight)
      let mapHeight = max(geo.size.height - meterHeight - actionBarHeight - 24, minMapHeight)

      VStack(spacing: 12) {
        ZStack(alignment: .topTrailing) {
          meterPanelView
          MeterSwitcherBar(style: $meterFaceStyle, mode: $meterRenderMode, digitStyle: $digitWheelStyle)
            .padding(.top, 6)
            .padding(.trailing, 8)
        }
        .frame(height: meterHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, safeAreaTop + 8)

        ZStack {
          LiveRouteMap(points: meterStore.points, followLatest: meterStore.isOnTrip)
            .frame(height: mapHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
        }
        .overlay(alignment: .topLeading) {
          conditionsOverlay
            .padding(.top, 10)
            .padding(.leading, 10)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)

        HStack {
          Spacer()
          bottomControls
        }
        .frame(height: actionBarHeight)
        .padding(.horizontal, 12)
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
    }
  }

  @ViewBuilder
  private var meterPanelView: some View {
    switch meterFaceStyle {
    case .superMeter:
      if meterRenderMode == .full {
        SuperFullMeterPanel(tripState: meterStore.tripState, fare: meterStore.fare, digitStyle: digitWheelStyle)
      } else {
        SuperDisplayPanel(tripState: meterStore.tripState, fare: meterStore.fare, digitStyle: digitWheelStyle)
      }
    case .digital:
      if meterRenderMode == .full {
        DigitalFullMeterPanel(tripState: meterStore.tripState, fare: meterStore.fare)
      } else {
        DigitalDisplayPanel(tripState: meterStore.tripState, fare: meterStore.fare)
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .safeAreaInsets.top ?? 0
  }

  private var safeAreaBottom: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .safeAreaInsets.bottom ?? 0
  }

  private var bottomControls: some View {
    HStack(alignment: .bottom, spacing: 8) {
      tripToggleButton
      waitToggleButton
      meterControlCluster
    }
  }

  private var conditionsOverlay: some View {
    HStack(spacing: 6) {
      MiniConditionChip(title: "Rain", subtitle: "ಮಳೆ", isOn: bindingFor(\.isRaining))
      MiniConditionChip(title: "Night", subtitle: "ರಾತ್ರಿ", isOn: bindingFor(\.isNight))
        .allowsHitTesting(false)
      MiniConditionChip(title: "Traffic", subtitle: "ಟ್ರಾಫಿಕ್", isOn: bindingFor(\.isHeavyTraffic))
    }
    .padding(6)
    .background(Theme.card.opacity(0.85))
    .clipShape(Capsule())
  }

  private var tripToggleButton: some View {
    Button {
      if meterStore.isOnTrip {
        meterStore.stopTrip(tripStore: tripStore)
      } else {
        meterStore.startTrip(settings: settingsStore.settings)
      }
    } label: {
      MiniFlipSignView(isOnTrip: meterStore.isOnTrip)
    }
    .buttonStyle(.plain)
  }

  private var waitToggleButton: some View {
    Button {
      meterStore.toggleWaiting()
    } label: {
      VStack(spacing: 2) {
        Image(systemName: meterStore.isWaiting ? "pause.circle.fill" : "pause.circle")
          .font(.system(size: 16, weight: .semibold))
        Text("Wait")
          .font(.nammaBody(8))
        Text("ನಿಲ್ಲಿಕೆ")
          .font(.nammaBody(7))
      }
      .foregroundStyle(Theme.ink)
      .frame(width: 64, height: 48)
      .background(meterStore.isWaiting ? Theme.coral.opacity(0.8) : Theme.card.opacity(0.9))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
    }
    .buttonStyle(.plain)
    .disabled(!meterStore.isOnTrip)
    .opacity(meterStore.isOnTrip ? 1 : 0.6)
  }

  private var meterControlCluster: some View {
    let details: [(String, String)] = [
      ((meterStore.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2))) + " km", "Distance · ದೂರ"),
      (formattedElapsed(meterStore.elapsed), "Time · ಸಮಯ"),
      (formattedElapsed(meterStore.waitingDuration), "Wait · ನಿಲ್ಲಿಕೆ"),
      (meterStore.currentSpeedKph.formatted(.number.precision(.fractionLength(1))) + " km/h", "Speed · ವೇಗ")
    ]
    let expandedHeight = (fareTileSize.height * CGFloat(details.count + 1)) + (fareTileSpacing * CGFloat(details.count))

    return VStack(alignment: .trailing, spacing: fareTileSpacing) {
      ForEach(details.indices, id: \.self) { index in
        FareInfoTile(
          valueText: details[index].0,
          labelText: details[index].1,
          size: fareTileSize,
          showsChevron: false,
          isExpanded: showMeterPanel
        )
        .opacity(showMeterPanel ? 1 : 0)
        .scaleEffect(showMeterPanel ? 1 : 0.96, anchor: .bottomTrailing)
      }
      Button {
        showMeterPanel.toggle()
      } label: {
        FareInfoTile(
          valueText: meterStore.fare.formatted(.currency(code: "INR").precision(.fractionLength(0))),
          labelText: "Fare · ಭಾಡೆ",
          size: fareTileSize,
          showsChevron: true,
          isExpanded: showMeterPanel
        )
      }
      .buttonStyle(.plain)
    }
    .frame(
      width: fareTileSize.width,
      height: showMeterPanel ? expandedHeight : fareTileSize.height,
      alignment: .bottom
    )
    .clipped()
    .animation(.spring(response: 0.34, dampingFraction: 0.82), value: showMeterPanel)
  }

  private func bindingFor(_ keyPath: WritableKeyPath<TripConditions, Bool>) -> Binding<Bool> {
    Binding(
      get: { meterStore.conditions[keyPath: keyPath] },
      set: { meterStore.conditions[keyPath: keyPath] = $0 }
    )
  }
}

enum MeterFaceStyle: String, CaseIterable, Identifiable {
  case superMeter = "Super"
  case digital = "Neo Digital"

  var id: String { rawValue }
  var label: String { rawValue }
  var systemImage: String {
    switch self {
    case .superMeter:
      return "gauge.with.dots.needle.67percent"
    case .digital:
      return "display"
    }
  }
}

enum MeterRenderMode: String, CaseIterable, Identifiable {
  case full = "Full"
  case displayOnly = "Display"

  var id: String { rawValue }
  var label: String { rawValue }
}

enum DigitWheelStyle: String, CaseIterable, Identifiable {
  case drum = "Drum"
  case disk = "Disk"

  var id: String { rawValue }
  var label: String { rawValue }
}

struct MeterSwitcherBar: View {
  @Binding var style: MeterFaceStyle
  @Binding var mode: MeterRenderMode
  @Binding var digitStyle: DigitWheelStyle

  var body: some View {
    HStack(spacing: 6) {
      Menu {
        ForEach(MeterFaceStyle.allCases) { option in
          Button {
            style = option
          } label: {
            Label(option.label, systemImage: option.systemImage)
          }
        }
      } label: {
        HStack(spacing: 4) {
          Image(systemName: style.systemImage)
            .font(.system(size: 10, weight: .semibold))
          Text(style.label)
            .font(.nammaBody(10))
          Image(systemName: "chevron.down")
            .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Theme.ink)
      }

      Picker("Mode", selection: $mode) {
        ForEach(MeterRenderMode.allCases) { option in
          Text(option.label).tag(option)
        }
      }
      .pickerStyle(.segmented)
      .frame(width: 120)

      Menu {
        ForEach(DigitWheelStyle.allCases) { option in
          Button {
            digitStyle = option
          } label: {
            Text(option.label)
          }
        }
      } label: {
        HStack(spacing: 4) {
          Text(digitStyle.label)
            .font(.nammaBody(10))
          Image(systemName: "chevron.down")
            .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Theme.ink)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Theme.card.opacity(0.92))
    .clipShape(Capsule())
    .shadow(color: Theme.pastelShadow(), radius: 8, x: 0, y: 4)
  }
}

struct SuperFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let digitStyle: DigitWheelStyle
  @State private var hirePulse = false

  private let caseTop = Color(red: 0.17, green: 0.18, blue: 0.19)
  private let caseBottom = Color(red: 0.06, green: 0.06, blue: 0.07)
  private let metalPanel = Color(red: 0.9, green: 0.9, blue: 0.88)
  private let metalEdge = Color(red: 0.7, green: 0.7, blue: 0.68)
  private let displayEdge = Color(red: 0.22, green: 0.22, blue: 0.24)
  private let printInk = Color.black.opacity(0.82)

  var body: some View {
    GeometryReader { geo in
      let desiredBodyWidth = geo.size.width * 0.78
      let bodyHeightForWidth = desiredBodyWidth * 1.28
      let canopyHeightForWidth = bodyHeightForWidth * 0.18
      let baseHeightForWidth = bodyHeightForWidth * 0.14
      let totalHeightForWidth = bodyHeightForWidth + canopyHeightForWidth * 0.85 + baseHeightForWidth
      let scale = min(1, geo.size.height / totalHeightForWidth)
      let bodyWidth = desiredBodyWidth * scale
      let bodyHeight = bodyHeightForWidth * scale
      let canopyHeight = canopyHeightForWidth * scale
      let baseHeight = baseHeightForWidth * scale

      ZStack {
        Color.clear

        VStack(spacing: -bodyHeight * 0.08) {
          SuperMeterCanopyShape()
            .fill(
              LinearGradient(
                colors: [caseTop, caseBottom],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: bodyWidth * 0.9, height: canopyHeight)
            .overlay(
              SuperMeterCanopyShape()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)

          // Dial layering: outer casing -> inner white panel -> dial face content -> manufacturer plate.
          ZStack {
            RoundedRectangle(cornerRadius: bodyWidth * 0.1, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [caseTop, caseBottom],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: bodyWidth * 0.1, style: .continuous)
                  .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
              )
              .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 10)

            RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous)
              .fill(metalPanel)
              .padding(.horizontal, bodyWidth * 0.08)
              .padding(.top, bodyHeight * 0.12)
              .padding(.bottom, bodyHeight * 0.3)
              .overlay(
                RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous)
                  .stroke(metalEdge, lineWidth: 1)
                  .padding(.horizontal, bodyWidth * 0.08)
                  .padding(.top, bodyHeight * 0.12)
                  .padding(.bottom, bodyHeight * 0.3)
              )

            // Dial face content stack (title, subtitle, display window, fare row).
            SuperMeterFace(
              bodyWidth: bodyWidth,
              bodyHeight: bodyHeight,
              tripState: tripState,
              fare: fare,
              displayEdge: displayEdge,
              printInk: printInk,
              pulse: hirePulse,
              digitStyle: digitStyle
            )
            .padding(.horizontal, bodyWidth * 0.08)
            .padding(.top, bodyHeight * 0.12)
            .padding(.bottom, bodyHeight * 0.3)
            .clipShape(RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous))

//            Text("SUPER")
//              .font(.system(size: bodyWidth * 0.08, weight: .bold, design: .rounded))
//              .foregroundStyle(Color.white.opacity(0.12))
//              .rotationEffect(.degrees(-90))
//              .offset(x: -bodyWidth * 0.45, y: bodyHeight * 0.08)

            SuperMeterPlate(bodyWidth: bodyWidth, bodyHeight: bodyHeight, printInk: printInk, metalPanel: metalPanel, metalEdge: metalEdge)
              .offset(y: bodyHeight * 0.32)
          }
          .frame(width: bodyWidth, height: bodyHeight)

          SuperMeterBaseView(width: bodyWidth * 0.62, height: baseHeight)
            .offset(y: baseHeight * -0.05)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      if tripState == .forHire {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
          hirePulse = true
        }
      }
    }
    .onChange(of: tripState) { _, newValue in
      if newValue == .forHire {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
          hirePulse = true
        }
      } else {
        hirePulse = false
      }
    }
  }
}

struct SuperDisplayPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let digitStyle: DigitWheelStyle
  @State private var hirePulse = false

  private let displayEdge = Color(red: 0.22, green: 0.22, blue: 0.24)

  var body: some View {
    GeometryReader { geo in
      let padding = min(geo.size.width, geo.size.height) * 0.06
      let availableWidth = max(geo.size.width - padding * 2, 0)
      let availableHeight = max(geo.size.height - padding * 2, 0)
      let aspect: CGFloat = 3.2
      let width = min(availableWidth, availableHeight * aspect)
      let height = width / aspect

      ZStack {
        Color.clear
        MeterDisplayWindow(
          tripState: tripState,
          fare: fare,
          displayEdge: displayEdge,
          pulse: hirePulse,
          digitStyle: digitStyle
        )
        .frame(width: width, height: height)
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .onAppear {
      if tripState == .forHire {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
          hirePulse = true
        }
      }
    }
    .onChange(of: tripState) { _, newValue in
      if newValue == .forHire {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
          hirePulse = true
        }
      } else {
        hirePulse = false
      }
    }
  }
}

struct SuperMeterFace: View {
  let bodyWidth: CGFloat
  let bodyHeight: CGFloat
  let tripState: TripMeterState
  let fare: Double
  let displayEdge: Color
  let printInk: Color
  let pulse: Bool
  let digitStyle: DigitWheelStyle

  var body: some View {
    // Face layering: title -> subtitle -> display window -> RUPEES/FARE/PAISE row.
    VStack(spacing: bodyHeight * 0.03) {
      Text("Super")
        .font(.system(size: bodyWidth * 0.08, weight: .bold, design: .rounded))
        .foregroundStyle(printInk)
        .padding(.top, bodyHeight * 0.002)

      Text("AUTO RICKSHAW METER")
        .font(.system(size: bodyWidth * 0.045, weight: .semibold, design: .rounded))
        .foregroundStyle(printInk.opacity(0.75))

      MeterDisplayWindow(
        tripState: tripState,
        fare: fare,
        displayEdge: displayEdge,
        pulse: pulse,
        digitStyle: digitStyle
      )
      .frame(height: bodyHeight * 0.2)

      HStack(spacing: bodyWidth * 0.03) {
        Text("RUPEES")
          .font(.system(size: bodyWidth * 0.038, weight: .semibold, design: .rounded))
          .tracking(1.2)
        Text("FARE")
          .font(.system(size: bodyWidth * 0.08, weight: .heavy, design: .rounded))
          .foregroundStyle(Color(red: 0.78, green: 0.18, blue: 0.18))
          .tracking(1.0)
        Text("PAISE")
          .font(.system(size: bodyWidth * 0.038, weight: .semibold, design: .rounded))
          .tracking(1.2)
      }
      .foregroundStyle(printInk.opacity(0.7))
      .padding(.top, bodyHeight * 0.01)
      .padding(.bottom, bodyHeight * 0.02)
    }
    .padding(.horizontal, bodyWidth * 0.06)
    .padding(.top, bodyHeight * 0.05)
  }
}

struct SuperMeterPlate: View {
  let bodyWidth: CGFloat
  let bodyHeight: CGFloat
  let printInk: Color
  let metalPanel: Color
  let metalEdge: Color

  var body: some View {
    RoundedRectangle(cornerRadius: bodyWidth * 0.03, style: .continuous)
      .fill(
        LinearGradient(
          colors: [Color.white, metalPanel, metalEdge],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: bodyWidth * 0.03, style: .continuous)
          .stroke(Color.black.opacity(0.4), lineWidth: 0.8)
      )
      .frame(width: bodyWidth * 0.7, height: bodyHeight * 0.13)
      .overlay(
        VStack(spacing: bodyHeight * 0.012) {
          Text("Manufactured by")
            .font(.system(size: bodyWidth * 0.03, weight: .semibold, design: .rounded))
            .foregroundStyle(printInk.opacity(0.7))
          Text("Super METER MFG. CO.")
            .font(.system(size: bodyWidth * 0.04, weight: .bold, design: .rounded))
            .foregroundStyle(printInk)
          Text("MUNDHWA, PUNE · INDIA")
            .font(.system(size: bodyWidth * 0.028, weight: .medium, design: .rounded))
            .foregroundStyle(printInk.opacity(0.6))
        }
      )
  }
}

struct SuperMeterCanopyShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let peak = CGPoint(x: rect.midX, y: rect.minY)
    let leftTop = CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.28)
    let rightTop = CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.28)
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: leftTop)
    path.addQuadCurve(to: peak, control: CGPoint(x: rect.midX - rect.width * 0.14, y: rect.minY))
    path.addQuadCurve(to: rightTop, control: CGPoint(x: rect.midX + rect.width * 0.14, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    return path
  }
}

struct SuperMeterBaseView: View {
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: height * 0.35, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.12, green: 0.12, blue: 0.13),
              Color(red: 0.05, green: 0.05, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: height * 0.35, style: .continuous)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )

      HStack(spacing: width * 0.12) {
        Capsule()
          .fill(Color.black.opacity(0.7))
          .frame(width: width * 0.12, height: height * 0.55)
        Capsule()
          .fill(Color.black.opacity(0.7))
          .frame(width: width * 0.12, height: height * 0.55)
      }
    }
    .frame(width: width, height: height)
  }
}

struct DigitalFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  @State private var glowPulse = false

  private let bodyColor = Color(red: 0.09, green: 0.1, blue: 0.12)
  private let bezel = Color(red: 0.18, green: 0.2, blue: 0.24)
  private let accent = Color(red: 0.15, green: 0.8, blue: 0.9)

  var body: some View {
    GeometryReader { geo in
      let desiredWidth = geo.size.width * 0.78
      let bodyHeightForWidth = desiredWidth * 0.7
      let scale = min(1, geo.size.height / bodyHeightForWidth)
      let bodyWidth = desiredWidth * scale
      let bodyHeight = bodyHeightForWidth * scale

      ZStack {
        RoundedRectangle(cornerRadius: bodyWidth * 0.08, style: .continuous)
          .fill(
            LinearGradient(
              colors: [bodyColor, Color.black],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: bodyWidth * 0.08, style: .continuous)
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)

        VStack(spacing: bodyHeight * 0.08) {
          Text("DIGITAL FARE METER")
            .font(.system(size: bodyWidth * 0.05, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.7))

          DigitalMeterScreen(tripState: tripState, fare: fare, glow: glowPulse, accent: accent, bezel: bezel)
            .frame(height: bodyHeight * 0.32)

          DigitalButtonRow(width: bodyWidth)
        }
        .padding(.horizontal, bodyWidth * 0.12)
        .padding(.vertical, bodyHeight * 0.12)
      }
      .frame(width: bodyWidth, height: bodyHeight)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
        glowPulse = true
      }
    }
  }
}

struct DigitalDisplayPanel: View {
  let tripState: TripMeterState
  let fare: Double
  @State private var glowPulse = false

  private let bezel = Color(red: 0.2, green: 0.22, blue: 0.26)
  private let accent = Color(red: 0.15, green: 0.8, blue: 0.9)

  var body: some View {
    GeometryReader { geo in
      let padding = min(geo.size.width, geo.size.height) * 0.06
      let availableWidth = max(geo.size.width - padding * 2, 0)
      let availableHeight = max(geo.size.height - padding * 2, 0)
      let aspect: CGFloat = 3.4
      let width = min(availableWidth, availableHeight * aspect)
      let height = width / aspect

      ZStack {
        Color.clear
        DigitalMeterScreen(tripState: tripState, fare: fare, glow: glowPulse, accent: accent, bezel: bezel)
          .frame(width: width, height: height)
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
        glowPulse = true
      }
    }
  }
}

struct DigitalMeterScreen: View {
  let tripState: TripMeterState
  let fare: Double
  let glow: Bool
  let accent: Color
  let bezel: Color

  var body: some View {
    GeometryReader { geo in
      let textSize = min(geo.size.height * 0.55, 36)
      let glowColor = accent.opacity(glow ? 0.85 : 0.45)

      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color(red: 0.03, green: 0.06, blue: 0.08))
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(bezel, lineWidth: 2)
          )

        Text(tripState == .forHire ? "HIRE" : formattedFare())
          .font(.system(size: textSize, weight: .bold, design: .monospaced))
          .foregroundStyle(glowColor)
          .shadow(color: glowColor, radius: glow ? 12 : 6, x: 0, y: 0)
          .tracking(textSize * 0.06)
      }
    }
  }

  private func formattedFare() -> String {
    let value = max(0, Int(fare.rounded()))
    return String(format: "%04d", value)
  }
}

struct DigitalButtonRow: View {
  let width: CGFloat

  var body: some View {
    HStack(spacing: width * 0.07) {
      ForEach(0..<3) { index in
        Circle()
          .fill(Color(red: 0.18, green: 0.19, blue: 0.22))
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.12), lineWidth: 1)
          )
          .frame(width: width * 0.08, height: width * 0.08)
          .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
          .opacity(index == 1 ? 1 : 0.85)
      }
    }
  }
}

struct MeterDisplayWindow: View {
  let tripState: TripMeterState
  let fare: Double
  let displayEdge: Color
  let pulse: Bool
  let digitStyle: DigitWheelStyle

  var body: some View {
    GeometryReader { geo in
      let textSize = min(geo.size.height * 0.55, 28)
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color(red: 0.96, green: 0.95, blue: 0.93))
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(displayEdge, lineWidth: 2)
          )

        if tripState != .forHire {
          let digitData = formattedDigits()
          MeterDigitsRow(
            digits: digitData.digits,
            paiseStartIndex: digitData.paiseStartIndex,
            digitStyle: digitStyle
          )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 30)
            .padding(.leading, 0)
        } else {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(red: 0.78, green: 0.18, blue: 0.18))
            .overlay(
              Text("FOR HIRE")
                .font(.system(size: textSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(textSize * 0.06)
            )
            .padding(.horizontal, 10)
            .opacity(pulse ? 0.7 : 1.0)
        }
      }
    }
  }

  private func formattedDigits() -> (digits: [String], paiseStartIndex: Int) {
    let totalPaise = max(0, Int((fare * 100).rounded()))
    let rupees = totalPaise / 100
    let paise = totalPaise % 100
    let rupeesString = String(format: "%02d", rupees % 100)
    let paiseString = String(format: "%02d", paise)
    let combined = rupeesString + paiseString
    return (combined.map { String($0) }, rupeesString.count)
  }
}

struct MeterDigitsRow: View {
  let digits: [String]
  let paiseStartIndex: Int
  let digitStyle: DigitWheelStyle

  var body: some View {
    GeometryReader { geo in
      let largeSpacing: CGFloat = 20
      let smallSpacing: CGFloat = 2
      let count = max(digits.count, 1)
      let maxDigitWidth = geo.size.width / CGFloat(count)
      let digitWidth = maxDigitWidth * 0.72
      let totalGap = (0..<(count - 1)).reduce(CGFloat(0)) { partial, index in
        partial + gapSpacing(after: index, paiseStartIndex: paiseStartIndex, large: largeSpacing, small: smallSpacing)
      }
      let rowWidth = (digitWidth * CGFloat(count)) + totalGap

      HStack(spacing: 0) {
        ForEach(Array(digits.enumerated()), id: \.offset) { index, value in
          MeterDigitCell(digit: value, isAccent: index >= paiseStartIndex, digitStyle: digitStyle)
            .frame(width: digitWidth, height: geo.size.height * 0.92)
            .padding(.trailing, index < count - 1
              ? gapSpacing(after: index, paiseStartIndex: paiseStartIndex, large: largeSpacing, small: smallSpacing)
              : 0
            )
        }
      }
      .frame(width: rowWidth, alignment: .center)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
  }
}

private func gapSpacing(after index: Int, paiseStartIndex: Int, large: CGFloat, small: CGFloat) -> CGFloat {
  index >= paiseStartIndex ? small : large
}

struct MeterDigitCell: View {
  let digit: String
  let isAccent: Bool
  let digitStyle: DigitWheelStyle
  @State private var currentDigit: Int?
  @State private var wheelRotation: CGFloat = 0
  @State private var rollProgress: CGFloat = 0
  @State private var rollDirection: CGFloat = -1

  var body: some View {
    GeometryReader { geo in
      let height = geo.size.height
      let fontSize = min(height * 0.75, 28)
      let baseDigit = currentDigit ?? Int(digit) ?? 0
      let prevDigit = steppedDigit(from: baseDigit, by: -1)
      let nextDigit = steppedDigit(from: baseDigit, by: 1)
      let windowWidth = geo.size.width * 0.7
      let windowHeight = height * 0.78
      let windowShape = Capsule()
      let wheelFill: AnyShapeStyle = digitStyle == .disk
        ? AnyShapeStyle(
          RadialGradient(
            colors: [
              Color.white,
              Color(red: 0.94, green: 0.94, blue: 0.94),
              Color(red: 0.86, green: 0.86, blue: 0.86),
              Color(red: 0.97, green: 0.97, blue: 0.97)
            ],
            center: .center,
            startRadius: 2,
            endRadius: max(windowWidth, windowHeight) * 0.9
          )
        )
        : AnyShapeStyle(
          LinearGradient(
            colors: [
              Color.white,
              Color(red: 0.95, green: 0.95, blue: 0.95),
              Color(red: 0.88, green: 0.88, blue: 0.88),
              Color(red: 0.98, green: 0.98, blue: 0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      let wheelDiameter = max(windowWidth, windowHeight) * 1.45
      let stepAngle: CGFloat = 36
      let radius = windowHeight * 0.38
      let step = height * 0.32
      let rollOffset = rollDirection * step * rollProgress
      let verticalBias = windowHeight * 0.35

      // Window layering: oval cutout -> wheel disk -> digits -> highlight.
      ZStack {
        windowShape
          .fill(Color.black.opacity(0.78))
          .frame(width: windowWidth, height: windowHeight)
          .overlay(
            windowShape
              .stroke(Color.black.opacity(0.85), lineWidth: 1)
              .frame(width: windowWidth, height: windowHeight)
          )
          .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 2)

        ZStack {
          Circle()
            .fill(wheelFill)
            .frame(width: wheelDiameter, height: wheelDiameter)
            .overlay(
              Circle()
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
            )

          ZStack {
            if digitStyle == .disk {
              diskDigit(
                prevDigit,
                angle: -stepAngle + wheelRotation,
                radius: radius,
                fontSize: fontSize * 0.85,
                opacity: 0.35
              )

              diskDigit(
                String(baseDigit),
                angle: wheelRotation,
                radius: radius,
                fontSize: fontSize,
                opacity: 1
              )

              diskDigit(
                nextDigit,
                angle: stepAngle + wheelRotation,
                radius: radius,
                fontSize: fontSize * 0.85,
                opacity: 0.35
              )
            } else {
              drumDigit(
                prevDigit,
                offset: -step,
                fontSize: fontSize * 0.85,
                opacity: 0.35
              )
              drumDigit(
                String(baseDigit),
                offset: 0,
                fontSize: fontSize,
                opacity: 1
              )
              drumDigit(
                nextDigit,
                offset: step,
                fontSize: fontSize * 0.85,
                opacity: 0.35
              )
            }
          }
          .offset(y: (digitStyle == .drum ? rollOffset : 0) + (digitStyle == .disk ? verticalBias : 0))
          .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .mask(
          windowShape
            .frame(width: windowWidth, height: windowHeight)
            .padding(2)
        )
        .overlay(
          LinearGradient(
            colors: [Color.white.opacity(0.28), Color.clear, Color.black.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
          )
          .mask(
            windowShape
              .frame(width: windowWidth, height: windowHeight)
              .padding(2)
          )
        )
      }
      .overlay(
        windowShape
          .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
          .frame(width: windowWidth, height: windowHeight)
          .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
      )
    }
    .onAppear {
      if currentDigit == nil {
        currentDigit = Int(digit) ?? 0
      }
    }
    .onChange(of: digitStyle) { _, _ in
      wheelRotation = 0
      rollProgress = 0
    }
    .onChange(of: digit) { _, newValue in
      guard let newDigit = Int(newValue) else { return }
      guard let oldDigit = currentDigit else {
        currentDigit = newDigit
        return
      }
      if newDigit == oldDigit { return }

      let forward = (newDigit - oldDigit + 10) % 10
      if forward == 1 {
        animateRoll(to: newDigit, direction: -1)
      } else if forward == 9 {
        animateRoll(to: newDigit, direction: 1)
      } else {
        currentDigit = newDigit
        wheelRotation = 0
        rollProgress = 0
      }
    }
  }

  private func steppedDigit(from value: Int, by step: Int) -> String {
    let newValue = (value + step + 10) % 10
    return String(newValue)
  }

  private func animateRoll(to newDigit: Int, direction: CGFloat) {
    if digitStyle == .disk {
      wheelRotation = 0
      withAnimation(.easeInOut(duration: 0.24)) {
        wheelRotation = direction * 36
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
        currentDigit = newDigit
        wheelRotation = 0
      }
    } else {
      rollDirection = direction
      rollProgress = 0
      withAnimation(.easeInOut(duration: 0.22)) {
        rollProgress = 1
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
        currentDigit = newDigit
        rollProgress = 0
      }
    }
  }

  private func digitFont(for value: String, size: CGFloat) -> Font {
    if value == "0" {
      return .system(size: size, weight: .bold, design: .rounded)
    }
    return .system(size: size, weight: .bold, design: .monospaced)
  }

  private func digitColor(isAccent: Bool) -> Color {
    isAccent ? Color(red: 0.78, green: 0.16, blue: 0.18) : Color.black.opacity(0.85)
  }

  private func diskDigit(_ value: String, angle: CGFloat, radius: CGFloat, fontSize: CGFloat, opacity: CGFloat) -> some View {
    Text(value)
      .font(digitFont(for: value, size: fontSize))
      .foregroundStyle(digitColor(isAccent: isAccent).opacity(opacity))
      .scaleEffect(x: 0.94, y: 1.08)
      .rotationEffect(.degrees(-angle))
      .offset(y: -radius)
      .rotationEffect(.degrees(angle))
  }

  private func drumDigit(_ value: String, offset: CGFloat, fontSize: CGFloat, opacity: CGFloat) -> some View {
    Text(value)
      .font(digitFont(for: value, size: fontSize))
      .foregroundStyle(digitColor(isAccent: isAccent).opacity(opacity))
      .scaleEffect(x: 0.94, y: 1.08)
      .offset(y: offset)
  }
}


struct FlipSignView: View {
  let isOnTrip: Bool

  var body: some View {
    ZStack {
      SignFace(
        title: "For Hire",
        subtitle: "ಬಾಡಿಗೆಗೆ",
        helper: "Flip to start",
        color: Theme.coral
      )
      .opacity(isOnTrip ? 0 : 1)
      .rotation3DEffect(.degrees(isOnTrip ? 180 : 0), axis: (x: 0, y: 1, z: 0))

      SignFace(
        title: "On Trip",
        subtitle: "ಪ್ರಯಾಣ",
        helper: "Tap to stop",
        color: Theme.mint
      )
      .opacity(isOnTrip ? 1 : 0)
      .rotation3DEffect(.degrees(isOnTrip ? 0 : -180), axis: (x: 0, y: 1, z: 0))
    }
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOnTrip)
  }
}

struct SignFace: View {
  let title: String
  let subtitle: String
  let helper: String
  let color: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(color)
        .frame(height: 100)
        .overlay(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)

      VStack(spacing: 6) {
        Text(title)
          .font(.nammaDisplay(22))
          .foregroundStyle(Theme.ink)
        Text(subtitle)
          .font(.nammaBody(14))
          .foregroundStyle(Theme.ink.opacity(0.8))
        Text(helper)
          .font(.nammaBody(12))
          .foregroundStyle(Theme.ink.opacity(0.6))
      }
    }
  }
}

struct MiniFlipSignView: View {
  let isOnTrip: Bool

  var body: some View {
    ZStack {
      MiniSignFace(
        title: "For Hire",
        subtitle: "ಬಾಡಿಗೆಗೆ",
        color: Theme.coral
      )
      .opacity(isOnTrip ? 0 : 1)
      .rotation3DEffect(.degrees(isOnTrip ? 180 : 0), axis: (x: 0, y: 1, z: 0))

      MiniSignFace(
        title: "On Trip",
        subtitle: "ಪ್ರಯಾಣ",
        color: Theme.mint
      )
      .opacity(isOnTrip ? 1 : 0)
      .rotation3DEffect(.degrees(isOnTrip ? 0 : -180), axis: (x: 0, y: 1, z: 0))
    }
    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isOnTrip)
  }
}

struct MiniSignFace: View {
  let title: String
  let subtitle: String
  let color: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(color)
        .frame(height: 44)
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)

      VStack(spacing: 2) {
        Text(title)
          .font(.nammaDisplay(10))
          .foregroundStyle(Theme.ink)
          .lineLimit(1)
        Text(subtitle)
          .font(.nammaBody(7))
          .foregroundStyle(Theme.ink.opacity(0.8))
          .lineLimit(1)
      }
      .padding(.horizontal, 6)
    }
  }
}

struct FareInfoTile: View {
  let valueText: String
  let labelText: String
  let size: CGSize
  let showsChevron: Bool
  let isExpanded: Bool

  var body: some View {
    VStack(spacing: 2) {
      Text(valueText)
        .font(.nammaDisplay(12))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(labelText)
        .font(.nammaBody(7))
        .lineLimit(1)
    }
    .foregroundStyle(Theme.ink)
    .frame(width: size.width, height: size.height)
    .background(Theme.mango.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
    .overlay(alignment: .topTrailing) {
      if showsChevron {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(Theme.ink.opacity(0.7))
          .padding(6)
      }
    }
  }
}

struct MiniConditionChip: View {
  let title: String
  let subtitle: String
  @Binding var isOn: Bool

  var body: some View {
    Button {
      isOn.toggle()
    } label: {
      VStack(spacing: 2) {
        Text(title)
          .font(.nammaDisplay(9))
        Text(subtitle)
          .font(.nammaBody(7))
      }
      .foregroundStyle(isOn ? Theme.ink : Theme.ink.opacity(0.6))
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background(isOn ? Theme.mango.opacity(0.6) : Theme.card)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(Theme.ink.opacity(isOn ? 0.2 : 0.1), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}

struct LiveRouteMap: View {
  let points: [TripPoint]
  let followLatest: Bool
  @State private var cameraPosition: MapCameraPosition = .automatic

  var body: some View {
    Map(position: $cameraPosition) {
      if points.count > 1 {
        MapPolyline(coordinates: points.map { $0.coordinate })
          .stroke(Theme.ink, lineWidth: 4)
      }
      if let start = points.first?.coordinate {
        Marker("Start", coordinate: start)
      }
      if let end = points.last?.coordinate {
        Annotation("Now", coordinate: end, anchor: .bottom) {
          AutoLocationMarker()
        }
      }
    }
    .onAppear {
      updateCamera(points)
    }
    .onChange(of: points) { _, newPoints in
      updateCamera(newPoints)
    }
  }

  private func updateCamera(_ points: [TripPoint]) {
    guard let last = points.last else { return }

    if followLatest {
      let region = MKCoordinateRegion(center: last.coordinate, latitudinalMeters: 700, longitudinalMeters: 700)
      withAnimation(.easeInOut(duration: 0.5)) {
        cameraPosition = .region(region)
      }
    } else if let region = points.coordinateRegion() {
      cameraPosition = .region(region)
    }
  }
}

struct AutoLocationMarker: View {
  var body: some View {
    VStack(spacing: 4) {
      AutoRickshawIcon()
        .padding(6)
        .background(Theme.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
      Circle()
        .fill(Theme.ink.opacity(0.35))
        .frame(width: 6, height: 6)
    }
    .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
  }
}

struct AutoRickshawIcon: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(Theme.mango)
        .frame(width: 28, height: 14)
      RoundedRectangle(cornerRadius: 3, style: .continuous)
        .fill(Theme.ink.opacity(0.85))
        .frame(width: 14, height: 8)
        .offset(x: -4, y: -4)
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(Theme.sky.opacity(0.8))
        .frame(width: 8, height: 5)
        .offset(x: 6, y: -1)
      Circle()
        .fill(Theme.ink)
        .frame(width: 5, height: 5)
        .offset(x: -7, y: 6)
      Circle()
        .fill(Theme.ink)
        .frame(width: 5, height: 5)
        .offset(x: 7, y: 6)
    }
  }
}

#Preview {
  MeterView()
    .environment(SettingsStore())
    .environment(TripStore())
}
