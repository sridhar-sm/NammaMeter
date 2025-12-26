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
      ZStack {
        LiveRouteMap(points: meterStore.points, followLatest: meterStore.isOnTrip)
          .frame(width: geo.size.width, height: geo.size.height)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .stroke(Color.white.opacity(0.4), lineWidth: 1)
          )
          .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
      }
      .overlay(alignment: .topLeading) {
        conditionsOverlay
          .padding(.top, safeAreaTop + 8)
          .padding(.leading, 10)
      }
      .overlay(alignment: .bottomTrailing) {
        bottomControls
          .padding(10)
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
