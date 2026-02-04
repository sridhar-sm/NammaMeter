import SwiftUI

struct MeterPanelWithNotch: View {
  @Environment(MeterStore.self) private var meterStore
  let meterFaceStyle: MeterFaceStyle
  let meterRenderMode: MeterRenderMode
  let digitWheelStyle: DigitWheelStyle
  let topInset: CGFloat

  var body: some View {
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
}
