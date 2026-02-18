import SwiftUI

// MARK: - Main Panel

struct SuperElectronicFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  let isNight: Bool
  var cityVehicleLabel: String = ""

  private let metalPanel = MeterColorSchemes.SuperElectronic.metalPanel
  private let metalEdge = MeterColorSchemes.SuperElectronic.metalEdge

  var body: some View {
    MeterShell(style: .superElectronic) { bodyWidth, bodyHeight in
      VStack(spacing: bodyHeight * 0.02) {
        // Top brand plate
        SuperElectronicBrandPlate(width: bodyWidth * 0.85, height: bodyHeight * 0.08)

        // Main LED display area
        SuperElectronicLEDDisplay(
          tripState: tripState,
          fare: fare,
          waitingDuration: waitingDuration,
          distanceKm: distanceMeters / 1000,
          isNight: isNight,
          width: bodyWidth * 0.88,
          height: bodyHeight * 0.52
        )

        // Bottom manufacturer plate
        SuperElectronicManufacturerPlate(
          width: bodyWidth * 0.85,
          height: bodyHeight * 0.14,
          metalPanel: metalPanel,
          metalEdge: metalEdge
        )

        if !cityVehicleLabel.isEmpty {
          MeterCityVehicleLabel(text: cityVehicleLabel, fontSize: bodyHeight * 0.03)
        }
      }
      .padding(.vertical, bodyHeight * 0.06)
    }
  }
}

// MARK: - Brand Plate

struct SuperElectronicBrandPlate: View {
  let width: CGFloat
  let height: CGFloat

  private let plateBackground = MeterColorSchemes.SuperElectronic.plateBackground
  private let printInk = Color.black.opacity(0.85)

  var body: some View {
    RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
      .fill(plateBackground)
      .overlay(
        RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
          .stroke(Color.black.opacity(0.3), lineWidth: 0.8)
      )
      .frame(width: width, height: height)
      .overlay(
        HStack(spacing: width * 0.02) {
          // Diamond logo
          SuperMeterLogo(size: height * 0.6)
          Text("Super")
            .font(.system(size: height * 0.45, weight: .bold, design: .rounded))
            .foregroundStyle(printInk)
          Text("METER MFG. CO.")
            .font(.system(size: height * 0.32, weight: .semibold, design: .rounded))
            .foregroundStyle(printInk.opacity(0.8))
        }
      )
  }
}

// MARK: - Super Meter Logo

struct SuperMeterLogo: View {
  let size: CGFloat

  var body: some View {
    ZStack {
      // Diamond shape with pattern
      Diamond()
        .fill(MeterColorSchemes.SuperElectronic.accentBlue)
        .frame(width: size, height: size)
      Diamond()
        .stroke(Color.white.opacity(0.6), lineWidth: 1)
        .frame(width: size * 0.6, height: size * 0.6)
    }
  }
}

struct Diamond: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
    path.closeSubpath()
    return path
  }
}

// MARK: - LED Display

struct SuperElectronicLEDDisplay: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceKm: Double
  let isNight: Bool
  let width: CGFloat
  let height: CGFloat

  private let displayBackground = MeterColorSchemes.SuperElectronic.displayBackground
  private let bezelColor = MeterColorSchemes.SuperElectronic.bezel
  private let labelColor = MeterColorSchemes.SuperElectronic.labelLight

  var body: some View {
    RoundedRectangle(cornerRadius: width * 0.03, style: .continuous)
      .fill(displayBackground)
      .overlay(
        RoundedRectangle(cornerRadius: width * 0.03, style: .continuous)
          .stroke(bezelColor, lineWidth: 3)
      )
      .frame(width: width, height: height)
      .overlay(
        VStack(spacing: height * 0.04) {
          // Fare row
          SuperElectronicFareRow(
            fare: fare,
            tripState: tripState,
            width: width * 0.92,
            height: height * 0.32
          )

          // Wait/Distance row
          SuperElectronicInfoRow(
            tripState: tripState,
            waitingDuration: waitingDuration,
            distanceKm: distanceKm,
            width: width * 0.92,
            height: height * 0.22
          )

          // Status bar
          SuperElectronicStatusBar(
            tripState: tripState,
            isNight: isNight,
            width: width * 0.92,
            height: height * 0.28
          )
        }
        .padding(.vertical, height * 0.04)
      )
  }
}

// MARK: - Fare Row

struct SuperElectronicFareRow: View {
  let fare: Double
  let tripState: TripMeterState
  let width: CGFloat
  let height: CGFloat

  private let labelColor = MeterColorSchemes.SuperElectronic.labelMedium

  var body: some View {
    HStack(spacing: 0) {
      // FARE label with rupee symbol
      VStack(alignment: .leading, spacing: 2) {
        Text("FARE")
          .font(.system(size: height * 0.22, weight: .semibold, design: .rounded))
        Text("₹")
          .font(.system(size: height * 0.28, weight: .bold, design: .rounded))
      }
      .foregroundStyle(labelColor)
      .frame(width: width * 0.15, alignment: .leading)

      Spacer()

      // LED digits - 3 rupees + decimal + 2 paise
      if tripState == .forHire {
        // Show "For" in middle 3 positions (positions 1, 2, 3)
        ForHireFareDisplay(digitHeight: height * 0.85)
      } else {
        FareDigitsDisplay(fare: fare, digitHeight: height * 0.85)
      }

      Spacer()

      // Ps. label
      Text("Ps.")
        .font(.system(size: height * 0.22, weight: .semibold, design: .rounded))
        .foregroundStyle(labelColor)
        .frame(width: width * 0.1, alignment: .trailing)
    }
    .frame(width: width, height: height)
  }
}

struct FareDigitsDisplay: View {
  let fare: Double
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .red

  var body: some View {
    let totalPaise = max(0, Int((fare * 100).rounded()))
    let rupees = totalPaise / 100
    let paise = totalPaise % 100

    // Build rupee values with leading zero blanking
    let r2 = (rupees / 100) % 10
    let r1 = (rupees / 10) % 10
    let r0 = rupees % 10
    let rupeeValues: [LED7SegmentValue] = [
      r2 > 0 ? .digit(r2) : .blank,
      (r2 > 0 || r1 > 0) ? .digit(r1) : .blank,
      .digit(r0)
    ]

    // Paise values (always show both)
    let p1 = paise / 10
    let p0 = paise % 10
    let paiseValues: [LED7SegmentValue] = [.digit(p1), .digit(p0)]

    HStack(spacing: digitHeight * 0.12) {
      LEDDigitGroup(
        digitCount: 3,
        height: digitHeight,
        colorScheme: colorScheme,
        decimalPosition: 2,
        values: rupeeValues
      )

      LEDDigitGroup(
        digitCount: 2,
        height: digitHeight,
        colorScheme: colorScheme,
        values: paiseValues
      )
    }
  }
}

struct ForHireFareDisplay: View {
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .red

  var body: some View {
    // Show "For" across positions with dim decimal
    let values: [LED7SegmentValue] = [
      .blank,
      .character("F"),
      .character("o"),
      .character("r"),
      .blank
    ]

    HStack(spacing: digitHeight * 0.12) {
      // First 3 digits (blank, F, o) with dim decimal after
      LEDDigitGroup(
        digitCount: 3,
        height: digitHeight,
        colorScheme: colorScheme,
        values: Array(values[0...2])
      )

      // Dim decimal point
      LEDDecimalPoint(isActive: false, colorScheme: colorScheme, size: digitHeight * 0.12)
        .offset(y: digitHeight * 0.4)

      // Last 2 digits (r, blank)
      LEDDigitGroup(
        digitCount: 2,
        height: digitHeight,
        colorScheme: colorScheme,
        values: Array(values[3...4])
      )
    }
  }
}

// MARK: - Info Row (Wait/Distance)

struct SuperElectronicInfoRow: View {
  let tripState: TripMeterState
  let waitingDuration: TimeInterval
  let distanceKm: Double
  let width: CGFloat
  let height: CGFloat

  private let labelColor = MeterColorSchemes.SuperElectronic.labelMedium

  var body: some View {
    HStack(spacing: 0) {
      // WAIT RTC label
      VStack(alignment: .leading, spacing: 1) {
        Text("WAIT")
          .font(.system(size: height * 0.28, weight: .semibold, design: .rounded))
        Text("RTC")
          .font(.system(size: height * 0.22, weight: .medium, design: .rounded))
      }
      .foregroundStyle(labelColor)
      .frame(width: width * 0.15, alignment: .leading)

      Spacer()

      // Wait time display (MM:SS) - show "HI" in For Hire state
      WaitTimeDisplay(duration: waitingDuration, digitHeight: height * 0.75, showBlank: false, showForHire: tripState == .forHire)

      Spacer()

      // Distance display - show "rE" in For Hire state
      DistanceDisplay(distanceKm: distanceKm, digitHeight: height * 0.75, showBlank: false, showForHire: tripState == .forHire)

      Spacer()

      // DIST label
      Text("DIST")
        .font(.system(size: height * 0.28, weight: .semibold, design: .rounded))
        .foregroundStyle(labelColor)
        .frame(width: width * 0.12, alignment: .trailing)
    }
    .frame(width: width, height: height)
  }
}

struct WaitTimeDisplay: View {
  let duration: TimeInterval
  let digitHeight: CGFloat
  var showBlank: Bool = false
  var showForHire: Bool = false
  var colorScheme: LEDColorScheme = .red

  private var displayValues: (values: [LED7SegmentValue], colonActive: Bool) {
    if showForHire {
      return ([.blank, .blank, .character("H"), .character("I")], false)
    } else if showBlank {
      return ([.blank, .blank, .blank, .blank], false)
    } else {
      let totalSeconds = Int(duration)
      let minutes = (totalSeconds / 60) % 100
      let seconds = totalSeconds % 60
      return ([
        .digit(minutes / 10),
        .digit(minutes % 10),
        .digit(seconds / 10),
        .digit(seconds % 10)
      ], true)
    }
  }

  var body: some View {
    let (values, colonActive) = displayValues

    HStack(spacing: digitHeight * 0.08) {
      LEDDigitGroup(
        digitCount: 2,
        height: digitHeight,
        colorScheme: colorScheme,
        isSmall: true,
        values: Array(values[0...1])
      )

      LEDColon(isActive: colonActive, colorScheme: colorScheme, height: digitHeight)

      LEDDigitGroup(
        digitCount: 2,
        height: digitHeight,
        colorScheme: colorScheme,
        isSmall: true,
        values: Array(values[2...3])
      )
    }
  }
}

struct DistanceDisplay: View {
  let distanceKm: Double
  let digitHeight: CGFloat
  var showBlank: Bool = false
  var showForHire: Bool = false
  var colorScheme: LEDColorScheme = .red

  private var displayValues: (integerValues: [LED7SegmentValue], decimalValue: LED7SegmentValue, decimalActive: Bool) {
    if showForHire {
      return ([.character("r"), .character("E"), .blank], .blank, false)
    } else if showBlank {
      return ([.blank, .blank, .blank], .blank, false)
    } else {
      let totalTenths = Int((distanceKm * 10).rounded()) % 10000
      let d2raw = (totalTenths / 1000) % 10
      let d1raw = (totalTenths / 100) % 10
      let d0raw = (totalTenths / 10) % 10
      let decimalRaw = totalTenths % 10
      return ([
        d2raw > 0 ? .digit(d2raw) : .blank,
        (d2raw > 0 || d1raw > 0) ? .digit(d1raw) : .blank,
        .digit(d0raw)
      ], .digit(decimalRaw), true)
    }
  }

  var body: some View {
    let (integerValues, decimalValue, decimalActive) = displayValues

    HStack(spacing: digitHeight * 0.08) {
      LEDDigitGroup(
        digitCount: 3,
        height: digitHeight,
        colorScheme: colorScheme,
        isSmall: true,
        values: integerValues
      )

      LEDDecimalPoint(isActive: decimalActive, colorScheme: colorScheme, size: digitHeight * 0.08)
        .offset(y: digitHeight * 0.35)

      LED7SegmentDigit(value: decimalValue, height: digitHeight, colorScheme: colorScheme, isSmall: true)
    }
  }
}

// MARK: - Status Bar

struct SuperElectronicStatusBar: View {
  let tripState: TripMeterState
  let isNight: Bool
  let width: CGFloat
  let height: CGFloat

  private let labelColor = MeterColorSchemes.SuperElectronic.labelDark
  private let dimColor = MeterColorSchemes.SuperElectronic.dim

  var body: some View {
    HStack(spacing: 0) {
      // Serial number section
      HStack(spacing: 4) {
        Text("Sr.No.EM")
          .font(.system(size: height * 0.16, weight: .medium, design: .rounded))
          .foregroundStyle(labelColor)
        Text("78213")
          .font(.system(size: height * 0.18, weight: .bold, design: .monospaced))
          .foregroundStyle(labelColor.opacity(0.8))
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(dimColor)
          .clipShape(RoundedRectangle(cornerRadius: 3))
      }

      Spacer()

      // Status LEDs
      HStack(spacing: width * 0.03) {
        LEDStatusIndicator(
          label: "FOR\nHIRE",
          isActive: tripState == .forHire,
          height: height * 0.85
        )
        LEDStatusIndicator(
          label: "HIRED",
          isActive: tripState == .inProgress,
          height: height * 0.85
        )
        LEDStatusIndicator(
          label: "STOP",
          isActive: tripState == .complete,
          height: height * 0.85
        )
        LEDStatusIndicator(
          label: "NIGHT\nMODE",
          isActive: isNight && tripState != .forHire,
          height: height * 0.85
        )
      }

      Spacer()

      // Model approval
      VStack(alignment: .trailing, spacing: 1) {
        Text("Model Approval No.")
          .font(.system(size: height * 0.12, weight: .medium, design: .rounded))
        Text("IND/09/05/118")
          .font(.system(size: height * 0.14, weight: .semibold, design: .monospaced))
      }
      .foregroundStyle(labelColor.opacity(0.7))
    }
    .frame(width: width, height: height)
  }
}


// MARK: - Manufacturer Plate

struct SuperElectronicManufacturerPlate: View {
  let width: CGFloat
  let height: CGFloat
  let metalPanel: Color
  let metalEdge: Color

  private let printInk = Color.black.opacity(0.82)

  var body: some View {
    RoundedRectangle(cornerRadius: width * 0.02, style: .continuous)
      .fill(
        LinearGradient(
          colors: [Color.white, metalPanel, metalEdge],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: width * 0.02, style: .continuous)
          .stroke(Color.black.opacity(0.4), lineWidth: 0.8)
      )
      .frame(width: width, height: height)
      .overlay(
        VStack(spacing: height * 0.08) {
          Text("Manufactured by")
            .font(.system(size: height * 0.16, weight: .medium, design: .rounded))
            .foregroundStyle(printInk.opacity(0.7))

          HStack(spacing: width * 0.015) {
            SuperMeterLogo(size: height * 0.28)
            Text("Super")
              .font(.system(size: height * 0.22, weight: .bold, design: .rounded))
              .foregroundStyle(printInk)
            Text("METER MFG. CO.")
              .font(.system(size: height * 0.16, weight: .semibold, design: .rounded))
              .foregroundStyle(printInk.opacity(0.85))
          }

          Text("59-B, MUNDHWA, PUNE - 411 036, MAHARASHTRA (INDIA)")
            .font(.system(size: height * 0.12, weight: .medium, design: .rounded))
            .foregroundStyle(printInk.opacity(0.6))
        }
      )
  }
}


// MARK: - Preview

#Preview {
  ZStack {
    MeterColorSchemes.Metal.highlight
      .ignoresSafeArea()

    SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 46.00,
      waitingDuration: 164,
      distanceMeters: 3300,
      isNight: true
    )
    .frame(height: 450)
  }
}
