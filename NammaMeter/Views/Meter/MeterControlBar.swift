import SwiftUI

struct MeterControlBar: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(TripStore.self) private var tripStore
  @Environment(MeterStore.self) private var meterStore
  let height: CGFloat
  @Binding var showMeterSettings: Bool
  var isLandscape: Bool = false

  var body: some View {
    GeometryReader { geo in
      let padding: CGFloat = isLandscape ? 4 : 10
      let spacing: CGFloat = 6
      let tileCount = CGFloat(5)

      if isLandscape {
        let availableWidth = max(geo.size.width - (padding * 2), 0)
        let availableHeight = max(geo.size.height - (padding * 2), 0)
        let tileHeight = max((availableHeight - spacing * (tileCount - 1)) / tileCount, 0)
        let metrics = ControlBarMetrics(
          tileSize: CGSize(width: availableWidth, height: tileHeight),
          iconSize: min(14, max(12, availableWidth * 0.35))
        )

        VStack(spacing: spacing) {
          tripToggleButton(metrics: metrics)
          waitToggleButton(metrics: metrics)
          nightConditionButton(metrics: metrics)
          vehicleSelectorButton(metrics: metrics)
          meterSettingsButton(metrics: metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(padding)
      } else {
        let availableWidth = max(geo.size.width - (padding * 2), 0)
        let availableHeight = max(geo.size.height - (CGFloat(4) * 2), 0)
        let tileWidth = max((availableWidth - spacing * (tileCount - 1)) / tileCount, 0)
        let metrics = ControlBarMetrics(
          tileSize: CGSize(width: tileWidth, height: availableHeight),
          iconSize: min(14, max(12, tileWidth * 0.35))
        )

        HStack(spacing: spacing) {
          tripToggleButton(metrics: metrics)
          waitToggleButton(metrics: metrics)
          nightConditionButton(metrics: metrics)
          vehicleSelectorButton(metrics: metrics)
          meterSettingsButton(metrics: metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, padding)
        .padding(.vertical, 4)
      }
    }
    .frame(width: isLandscape ? 56 : nil, height: isLandscape ? nil : height)
    .background(colorScheme == .dark ? Theme.darkControlBackground : Theme.card.opacity(0.92))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: Theme.pastelShadow(), radius: 8, x: 0, y: 4)
  }

  private func meterSettingsButton(metrics: ControlBarMetrics) -> some View {
    Button {
      showMeterSettings = true
    } label: {
      let bgColor = colorScheme == .dark ? Theme.darkControlBackground.opacity(1.2) : Theme.card.opacity(0.9)
      ControlTile(background: bgColor, size: metrics.tileSize) {
        Image(systemName: "gauge.with.dots.needle.67percent")
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Meter settings")
    .accessibilityIdentifier("meter.settingsButton")
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
        let profile = settingsStore.activeProfileForCurrentSelection
        meterStore.startTrip(
          settings: settingsStore.settings,
          cityId: cityInfo.cityId,
          cityName: cityInfo.cityName,
          surcharges: profile?.surcharges,
          perMinuteWhenSlow: profile?.rates.perMinuteWhenSlow,
          slowSpeedThresholdKph: profile?.rates.slowSpeedThresholdKph,
          vehicleType: profile?.vehicleType,
          currencyCode: profile?.cityKey.currencyCode,
          countryCode: profile?.cityKey.countryCode,
          whatIfFavorites: settingsStore.whatIfFavorites,
          whatIfProfileLookup: { settingsStore.whatIfProfile(for: $0) }
        )
      case .inProgress:
        meterStore.stopTrip(tripStore: tripStore)
      case .complete:
        meterStore.resetToForHire()
      }
    } label: {
      let bgColor: Color = switch meterStore.tripState {
      case .forHire: Theme.coral.opacity(0.85)
      case .inProgress: Theme.mint.opacity(0.85)
      case .complete: Theme.mango.opacity(0.85)
      }
      let iconName: String = switch meterStore.tripState {
      case .forHire: "play.fill"
      case .inProgress: "stop.fill"
      case .complete: "arrow.counterclockwise"
      }
      ControlTile(background: bgColor, size: metrics.tileSize) {
        Image(systemName: iconName)
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tripToggleAccessibilityLabel)
    .accessibilityIdentifier("meter.tripToggle")
  }

  private func waitToggleButton(metrics: ControlBarMetrics) -> some View {
    Button {
      meterStore.toggleWaiting()
    } label: {
      let isWaiting = meterStore.isWaiting
      let bgColor = isWaiting ? Theme.coral.opacity(0.85) : (colorScheme == .dark ? Theme.darkControlBackground.opacity(1.2) : Theme.card.opacity(0.9))
      ControlTile(background: bgColor, size: metrics.tileSize) {
        Image(systemName: isWaiting ? "play.fill" : "pause.fill")
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .disabled(!meterStore.isOnTrip)
    .opacity(meterStore.isOnTrip ? 1 : 0.6)
    .accessibilityLabel(meterStore.isWaiting ? "Resume trip" : "Pause trip")
    .accessibilityIdentifier("meter.waitToggle")
  }

  // MARK: - Vehicle selector

  private func vehicleSelectorButton(metrics: ControlBarMetrics) -> some View {
    let types = availableVehicleTypes
    let hasMultipleTypes = types.count > 1
    let defaultBg = colorScheme == .dark ? Theme.darkControlBackground.opacity(1.2) : Theme.card.opacity(0.9)
    let bgColor = hasMultipleTypes ? Theme.mint.opacity(0.85) : defaultBg

    return Button {
      cycleVehicleType()
    } label: {
      ControlTile(background: bgColor, size: metrics.tileSize) {
        Image(systemName: vehicleSymbol)
          .font(.system(size: metrics.iconSize, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .disabled(meterStore.tripState == .complete || !hasMultipleTypes)
    .opacity(meterStore.tripState == .complete || !hasMultipleTypes ? 0.6 : 1)
    .accessibilityLabel("Vehicle type: \(vehicleDisplayName)")
    .accessibilityIdentifier("meter.vehicleSelector")
  }

  private var vehicleSymbol: String {
    let vt = settingsStore.selectedVehicleType
      ?? settingsStore.activeProfileForCurrentSelection?.vehicleType
      ?? VehicleTypeCatalog.autoRickshaw
    return VehicleTypeCatalog.symbol(for: vt)
  }

  private var vehicleDisplayName: String {
    let vt = settingsStore.selectedVehicleType
      ?? settingsStore.activeProfileForCurrentSelection?.vehicleType
      ?? VehicleTypeCatalog.autoRickshaw
    return VehicleTypeCatalog.displayName(for: vt)
  }

  private var availableVehicleTypes: [String] {
    let cityId = settingsStore.activeCityInfo.cityId
    let group = settingsStore.availableCityGroups.first { $0.cityId == cityId }
    return group?.vehicleTypes ?? [VehicleTypeCatalog.autoRickshaw]
  }

  private func cycleVehicleType() {
    let types = availableVehicleTypes
    guard types.count > 1 else { return }
    let current = settingsStore.selectedVehicleType ?? types.first ?? VehicleTypeCatalog.autoRickshaw
    let currentIndex = types.firstIndex(of: current) ?? 0
    let nextIndex = (currentIndex + 1) % types.count
    settingsStore.selectVehicleType(types[nextIndex])

    if meterStore.tripState == .inProgress {
      meterStore.switchVehicleType(settingsStore: settingsStore)
    }
  }

  // MARK: - Helpers

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
