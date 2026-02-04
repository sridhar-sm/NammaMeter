import SwiftUI

struct MeterControlBar: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(TripStore.self) private var tripStore
  @Environment(MeterStore.self) private var meterStore
  let height: CGFloat
  @Binding var showMeterSettings: Bool

  var body: some View {
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

  private func nightConditionButton(metrics: ControlBarMetrics) -> some View {
    ConditionTileButton(
      systemImage: "moon.stars.fill",
      label: "Night",
      isOn: bindingFor(\.isNight),
      isInteractive: false,
      metrics: metrics
    )
  }

  private func tripToggleButton(metrics: ControlBarMetrics) -> some View {
    Button {
      switch meterStore.tripState {
      case .forHire:
        let cityInfo = settingsStore.activeCityInfo
        meterStore.startTrip(settings: settingsStore.settings, cityId: cityInfo.cityId, cityName: cityInfo.cityName)
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

  private func bindingFor(_ keyPath: WritableKeyPath<TripConditions, Bool>) -> Binding<Bool> {
    Binding(
      get: { meterStore.conditions[keyPath: keyPath] },
      set: { meterStore.conditions[keyPath: keyPath] = $0 }
    )
  }
}
