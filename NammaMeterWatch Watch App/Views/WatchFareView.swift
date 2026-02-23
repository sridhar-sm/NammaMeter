import SwiftUI

struct WatchFareView: View {
  @Environment(WatchTripStore.self) private var tripStore
  @Environment(WatchConnectivityService.self) private var connectivity

  var body: some View {
    VStack(spacing: 2) {
      // City name
      Text(tripStore.config?.cityName ?? "NammaMeter")
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.7))
        .lineLimit(1)

      // Vehicle type
      if let displayName = tripStore.config?.vehicleDisplayName, !displayName.isEmpty {
        Text(displayName)
          .font(.system(size: 12, weight: .regular, design: .rounded))
          .foregroundStyle(.white.opacity(0.5))
          .lineLimit(1)
      }

      // Fare digit display - matches phone's selected meter style
      fareDisplay
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .overlay(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(.white.opacity(0.3), lineWidth: 1)
        )

      // Trip controls
      tripControls
        .padding(.top, 4)
    }
    .padding(.horizontal, 4)
  }

  // MARK: - Fare Display

  @ViewBuilder
  private var fareDisplay: some View {
    switch tripStore.meterFaceStyle {
    case .superMeter:
      mechanicalFareDisplay
    case .superElectronic:
      ledFareDisplay(colorScheme: .red)
    case .goldenEagle:
      ledFareDisplay(colorScheme: LEDColorScheme(
        active: MeterColorSchemes.GoldenEagle.ledActive(isNight: tripStore.isNight),
        dim: MeterColorSchemes.GoldenEagle.ledDim
      ))
    case .digital:
      lcdFareDisplay
    case .brightDigital:
      ledFareDisplay(colorScheme: .red)
    }
  }

  // MARK: - Mechanical Digits (Super Mechanical)

  private var mechanicalFareDisplay: some View {
    GeometryReader { geo in
      let (digits, paiseStart) = formattedMechanicalDigits()
      MeterDigitsRow(
        digits: digits,
        paiseStartIndex: paiseStart,
        digitStyle: tripStore.digitWheelStyle
      )
      .frame(width: geo.size.width, height: geo.size.height)
    }
  }

  private func formattedMechanicalDigits() -> (digits: [String], paiseStartIndex: Int) {
    let totalPaise = max(0, Int((tripStore.fare * 100).rounded()))
    let rupees = totalPaise / 100
    let paise = totalPaise % 100
    let rupeesString = String(format: "%03d", rupees % 1000)
    let paiseString = String(format: "%01d", paise / 10)
    let combined = rupeesString + paiseString
    return (combined.map { String($0) }, rupeesString.count)
  }

  // MARK: - LED Digits (Super Electronic, Golden Eagle, Bright Digital)

  private func ledFareDisplay(colorScheme: LEDColorScheme) -> some View {
    GeometryReader { geo in
      FareDigitsDisplay(
        fare: tripStore.fare,
        digitHeight: geo.size.height * 0.85,
        colorScheme: colorScheme
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .background(MeterColorSchemes.LED.background)
    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
  }

  // MARK: - LCD Display (Neo Digital)

  private var lcdFareDisplay: some View {
    Text(tripStore.formattedFareLCD)
      .font(.system(size: 36, weight: .bold, design: .monospaced))
      .foregroundStyle(MeterColorSchemes.Digital.accent)
      .shadow(color: MeterColorSchemes.Digital.accent.opacity(0.4), radius: 6)
      .frame(maxWidth: .infinity)
      .background(MeterColorSchemes.Digital.screenBackground)
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
  }

  // MARK: - Trip Controls

  @ViewBuilder
  private var tripControls: some View {
    switch tripStore.tripState {
    case .forHire:
      Button {
        connectivity.sendCommand(.startTrip)
      } label: {
        Label("Start", systemImage: "play.fill")
          .font(.system(size: 15, weight: .semibold))
          .frame(maxWidth: .infinity)
      }
      .tint(.green)

    case .inProgress:
      HStack(spacing: 8) {
        Button {
          connectivity.sendCommand(.stopTrip)
        } label: {
          Image(systemName: "stop.fill")
            .font(.system(size: 14))
        }
        .tint(.red)

        Button {
          let command: WatchCommand = tripStore.isWaiting ? .exitWait : .enterWait
          connectivity.sendCommand(command)
        } label: {
          Image(systemName: tripStore.isWaiting ? "pause.circle.fill" : "pause.circle")
            .font(.system(size: 14))
        }
        .tint(tripStore.isWaiting ? .yellow : .gray)
      }

    case .complete:
      Button {
        connectivity.sendCommand(.resetTrip)
      } label: {
        Label("Reset", systemImage: "arrow.counterclockwise")
          .font(.system(size: 15, weight: .semibold))
          .frame(maxWidth: .infinity)
      }
      .tint(.blue)
    }
  }
}
