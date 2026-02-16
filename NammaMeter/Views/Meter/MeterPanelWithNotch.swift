import SwiftUI

struct MeterPanelWithNotch: View {
  @Environment(MeterStore.self) private var meterStore
  @Environment(SettingsStore.self) private var settingsStore
  let meterFaceStyle: MeterFaceStyle
  let meterRenderMode: MeterRenderMode
  let digitWheelStyle: DigitWheelStyle
  let topInset: CGFloat

  private var cityVehicleLabel: String {
    let cityName = settingsStore.activeCityInfo.cityName
    let vt = settingsStore.selectedVehicleType
      ?? settingsStore.activeProfileForCurrentSelection?.vehicleType
      ?? VehicleTypeCatalog.autoRickshaw
    return "\(cityName) · \(VehicleTypeCatalog.displayName(for: vt))"
  }

  var body: some View {
    switch meterFaceStyle {
    case .superMeter:
      if meterRenderMode == .full {
        SuperFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          digitStyle: digitWheelStyle,
          topInset: topInset,
          cityVehicleLabel: cityVehicleLabel
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
          topInset: topInset,
          cityVehicleLabel: cityVehicleLabel
        )
      } else {
        SuperElectronicFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset + 8,
          cityVehicleLabel: cityVehicleLabel
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
          topInset: topInset,
          cityVehicleLabel: cityVehicleLabel
        )
      } else {
        GoldenEagleFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          isNight: meterStore.conditions.isNight,
          topInset: topInset + 8,
          cityVehicleLabel: cityVehicleLabel
        )
        .padding(.horizontal, 12)
      }
    case .digital:
      // Neo renders the same layout in both full and display modes.
      DigitalFullMeterPanel(
        tripState: meterStore.tripState,
        fare: meterStore.fare,
        waitingDuration: meterStore.waitingDuration,
        distanceMeters: meterStore.distanceMeters,
        elapsed: meterStore.elapsed,
        currentSpeedKph: meterStore.currentSpeedKph,
        isNight: meterStore.conditions.isNight,
        isWaiting: meterStore.isWaiting,
        settings: settingsStore.settings,
        cityName: settingsStore.activeCityInfo.cityName,
        cityVehicleLabel: cityVehicleLabel,
        points: meterStore.points,
        currentRoadName: meterStore.currentRoadName,
        topInset: topInset,
        surcharges: settingsStore.activeProfileForCurrentSelection?.surcharges,
        currencyCode: settingsStore.activeProfileForCurrentSelection?.cityKey.currencyCode ?? "INR"
      )
    case .brightDigital:
      if meterRenderMode == .full {
        BrightDigitalFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          topInset: topInset,
          cityVehicleLabel: cityVehicleLabel
        )
      } else {
        BrightDigitalFullMeterPanel(
          tripState: meterStore.tripState,
          fare: meterStore.fare,
          waitingDuration: meterStore.waitingDuration,
          distanceMeters: meterStore.distanceMeters,
          topInset: topInset + 8,
          cityVehicleLabel: cityVehicleLabel
        )
        .padding(.horizontal, 12)
      }
    }
  }
}
