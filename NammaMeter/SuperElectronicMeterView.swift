import SwiftUI

// MARK: - Dimensions

enum SuperElectronicDimensions {
  static let widthRatio: CGFloat = 0.88
  static let bodyAspect: CGFloat = 1.1

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    let bodyWidth = containerWidth * widthRatio
    return bodyWidth * bodyAspect
  }
}

// MARK: - Main Panel

struct SuperElectronicFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  let isNight: Bool
  let topInset: CGFloat

  private let caseTop = Color(red: 0.17, green: 0.18, blue: 0.19)
  private let caseBottom = Color(red: 0.06, green: 0.06, blue: 0.07)
  private let metalPanel = Color(red: 0.88, green: 0.87, blue: 0.85)
  private let metalEdge = Color(red: 0.7, green: 0.7, blue: 0.68)

  var body: some View {
    GeometryReader { geo in
      let desiredBodyWidth = geo.size.width * SuperElectronicDimensions.widthRatio
      let bodyHeightForWidth = desiredBodyWidth * SuperElectronicDimensions.bodyAspect
      let scale = min(1, geo.size.height / bodyHeightForWidth)
      let bodyWidth = desiredBodyWidth * scale
      let bodyHeight = bodyHeightForWidth * scale

      ZStack {
        // Main body
        RoundedRectangle(cornerRadius: bodyWidth * 0.08, style: .continuous)
          .fill(
            LinearGradient(
              colors: [caseTop, caseBottom],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: bodyWidth * 0.08, style: .continuous)
              .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
          )
          .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 10)

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
        }
        .padding(.vertical, bodyHeight * 0.06)
      }
      .frame(width: bodyWidth, height: bodyHeight)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .offset(y: topInset)
    }
  }
}

// MARK: - Brand Plate

struct SuperElectronicBrandPlate: View {
  let width: CGFloat
  let height: CGFloat

  private let plateBackground = Color(red: 0.92, green: 0.91, blue: 0.89)
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
        .fill(Color(red: 0.2, green: 0.3, blue: 0.6))
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

  private let displayBackground = Color(red: 0.03, green: 0.04, blue: 0.05)
  private let bezelColor = Color(red: 0.12, green: 0.12, blue: 0.14)
  private let labelColor = Color(red: 0.85, green: 0.85, blue: 0.82)

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

  private let labelColor = Color(red: 0.75, green: 0.75, blue: 0.72)

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

  var body: some View {
    let totalPaise = max(0, Int((fare * 100).rounded()))
    let rupees = totalPaise / 100
    let paise = totalPaise % 100

    // 3 digits for rupees (leading zeros blank), 2 for paise
    let r2 = (rupees / 100) % 10  // hundreds
    let r1 = (rupees / 10) % 10   // tens
    let r0 = rupees % 10          // ones
    let p1 = paise / 10           // paise tens
    let p0 = paise % 10           // paise ones

    HStack(spacing: digitHeight * 0.12) {
      // Rupees digits (leading zeros blank)
      SevenSegmentDigit(digit: r2 > 0 ? r2 : nil, height: digitHeight)
      SevenSegmentDigit(digit: (r2 > 0 || r1 > 0) ? r1 : nil, height: digitHeight)
      SevenSegmentDigit(digit: r0, height: digitHeight)

      // Decimal point
      Circle()
        .fill(LEDColors.activeRed)
        .frame(width: digitHeight * 0.12, height: digitHeight * 0.12)
        .shadow(color: LEDColors.activeRed.opacity(0.8), radius: 4)
        .offset(y: digitHeight * 0.4)

      // Paise digits (always show both)
      SevenSegmentDigit(digit: p1, height: digitHeight)
      SevenSegmentDigit(digit: p0, height: digitHeight)
    }
  }
}

struct ForHireFareDisplay: View {
  let digitHeight: CGFloat

  var body: some View {
    // Show "For" in middle 3 positions (positions 1, 2, 3 of 5)
    // Position 0: blank, Position 1: F, Position 2: o, Position 3: r, Position 4: blank
    HStack(spacing: digitHeight * 0.12) {
      // Position 0: blank (hundreds rupees)
      SevenSegmentDigit(digit: nil, height: digitHeight)

      // Position 1: F (tens rupees)
      SevenSegmentDigit(digit: nil, height: digitHeight, character: "F")

      // Position 2: o (ones rupees)
      SevenSegmentDigit(digit: nil, height: digitHeight, character: "o")

      // Decimal point - dim
      Circle()
        .fill(LEDColors.dimRed)
        .frame(width: digitHeight * 0.12, height: digitHeight * 0.12)
        .offset(y: digitHeight * 0.4)

      // Position 3: r (tens paise)
      SevenSegmentDigit(digit: nil, height: digitHeight, character: "r")

      // Position 4: blank (ones paise)
      SevenSegmentDigit(digit: nil, height: digitHeight)
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

  private let labelColor = Color(red: 0.75, green: 0.75, blue: 0.72)

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

  var body: some View {
    let totalSeconds = Int(duration)
    let minutes = (totalSeconds / 60) % 100
    let seconds = totalSeconds % 60

    let m1 = showBlank ? nil : minutes / 10
    let m0 = showBlank ? nil : minutes % 10
    let s1 = showBlank ? nil : seconds / 10
    let s0 = showBlank ? nil : seconds % 10

    HStack(spacing: digitHeight * 0.08) {
      if showForHire {
        // Show blank in first two positions, "HI" in last two
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true)
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true)

        // Colon - dim
        VStack(spacing: digitHeight * 0.15) {
          Circle()
            .fill(LEDColors.dimRed)
            .frame(width: digitHeight * 0.1, height: digitHeight * 0.1)
          Circle()
            .fill(LEDColors.dimRed)
            .frame(width: digitHeight * 0.1, height: digitHeight * 0.1)
        }

        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true, character: "H")
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true, character: "I")
      } else {
        SevenSegmentDigit(digit: m1, height: digitHeight, isSmall: true)
        SevenSegmentDigit(digit: m0, height: digitHeight, isSmall: true)

        // Colon - dim when blank
        VStack(spacing: digitHeight * 0.15) {
          Circle()
            .fill(showBlank ? LEDColors.dimRed : LEDColors.activeRed)
            .frame(width: digitHeight * 0.1, height: digitHeight * 0.1)
          Circle()
            .fill(showBlank ? LEDColors.dimRed : LEDColors.activeRed)
            .frame(width: digitHeight * 0.1, height: digitHeight * 0.1)
        }
        .shadow(color: showBlank ? .clear : LEDColors.activeRed.opacity(0.6), radius: showBlank ? 0 : 2)

        SevenSegmentDigit(digit: s1, height: digitHeight, isSmall: true)
        SevenSegmentDigit(digit: s0, height: digitHeight, isSmall: true)
      }
    }
  }
}

struct DistanceDisplay: View {
  let distanceKm: Double
  let digitHeight: CGFloat
  var showBlank: Bool = false
  var showForHire: Bool = false

  var body: some View {
    // Show distance as 000.0 format (3 integer + 1 decimal)
    let totalTenths = Int((distanceKm * 10).rounded()) % 10000
    let d2raw = (totalTenths / 1000) % 10  // hundreds of km
    let d1raw = (totalTenths / 100) % 10   // tens of km
    let d0raw = (totalTenths / 10) % 10    // ones of km
    let decimalRaw = totalTenths % 10       // tenths of km

    // Leading zeros blank for d2 and d1
    let d2: Int? = showBlank ? nil : (d2raw > 0 ? d2raw : nil)
    let d1: Int? = showBlank ? nil : ((d2raw > 0 || d1raw > 0) ? d1raw : nil)
    let d0: Int? = showBlank ? nil : d0raw
    let decimal: Int? = showBlank ? nil : decimalRaw

    HStack(spacing: digitHeight * 0.08) {
      if showForHire {
        // Show "rE" in first two positions, rest blank
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true, character: "r")
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true, character: "E")
        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true)

        // Decimal point - dim
        Circle()
          .fill(LEDColors.dimRed)
          .frame(width: digitHeight * 0.08, height: digitHeight * 0.08)
          .offset(y: digitHeight * 0.35)

        SevenSegmentDigit(digit: nil, height: digitHeight, isSmall: true)
      } else {
        SevenSegmentDigit(digit: d2, height: digitHeight, isSmall: true)
        SevenSegmentDigit(digit: d1, height: digitHeight, isSmall: true)
        SevenSegmentDigit(digit: d0, height: digitHeight, isSmall: true)

        // Decimal point - dim when blank
        Circle()
          .fill(showBlank ? LEDColors.dimRed : LEDColors.activeRed)
          .frame(width: digitHeight * 0.08, height: digitHeight * 0.08)
          .shadow(color: showBlank ? .clear : LEDColors.activeRed.opacity(0.6), radius: showBlank ? 0 : 2)
          .offset(y: digitHeight * 0.35)

        SevenSegmentDigit(digit: decimal, height: digitHeight, isSmall: true)
      }
    }
  }
}

// MARK: - Status Bar

struct SuperElectronicStatusBar: View {
  let tripState: TripMeterState
  let isNight: Bool
  let width: CGFloat
  let height: CGFloat

  private let labelColor = Color(red: 0.65, green: 0.65, blue: 0.62)
  private let dimColor = Color(red: 0.2, green: 0.2, blue: 0.22)

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

struct LEDStatusIndicator: View {
  let label: String
  let isActive: Bool
  let height: CGFloat

  private let activeColor = Color(red: 1.0, green: 0.2, blue: 0.15)
  private let dimColor = Color(red: 0.15, green: 0.08, blue: 0.08)
  private let labelColor = Color(red: 0.6, green: 0.6, blue: 0.58)

  var body: some View {
    VStack(spacing: height * 0.08) {
      // LED dot
      Circle()
        .fill(isActive ? activeColor : dimColor)
        .frame(width: height * 0.22, height: height * 0.22)
        .overlay(
          Circle()
            .stroke(Color.black.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: isActive ? activeColor.opacity(0.8) : .clear, radius: isActive ? 6 : 0)

      // Label
      Text(label)
        .font(.system(size: height * 0.14, weight: .medium, design: .rounded))
        .foregroundStyle(labelColor)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .frame(width: height * 0.6)
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

// MARK: - Seven Segment Digit

enum LEDColors {
  static let activeRed = Color(red: 1.0, green: 0.2, blue: 0.12)
  static let dimRed = Color(red: 0.12, green: 0.06, blue: 0.06)
}

struct SevenSegmentDigit: View {
  let digit: Int?
  let height: CGFloat
  var isSmall: Bool = false
  var character: Character? = nil

  // Segment order: [a, b, c, d, e, f, g]
  // a=top, b=top-right, c=bottom-right, d=bottom, e=bottom-left, f=top-left, g=middle
  private let segmentMap: [Int: [Bool]] = [
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true]
  ]

  // Letter segment mappings for FOR HIRE display
  private let letterMap: [Character: [Bool]] = [
    "F": [true, false, false, false, true, true, true],   // a, f, g, e
    "o": [false, false, true, true, true, false, true],   // g, e, c, d
    "r": [false, false, false, false, true, false, true], // g, e
    "H": [false, true, true, false, true, true, true],    // f, b, g, e, c
    "I": [false, true, true, false, false, false, false], // b, c
    "E": [true, false, false, true, true, true, true]     // a, f, g, e, d
  ]

  var body: some View {
    let width = height * 0.6
    let segmentThickness = height * (isSmall ? 0.1 : 0.12)
    let segmentLength = height * 0.38

    let segments: [Bool] = {
      if let char = character {
        return letterMap[char] ?? Array(repeating: false, count: 7)
      } else if let d = digit {
        return segmentMap[d] ?? Array(repeating: false, count: 7)
      } else {
        return Array(repeating: false, count: 7)
      }
    }()

    ZStack {
      // Background for digit area
      RoundedRectangle(cornerRadius: 2)
        .fill(Color.black.opacity(0.3))
        .frame(width: width, height: height)

      // Segment a (top horizontal)
      SegmentShape(isHorizontal: true)
        .fill(segments[0] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentLength, height: segmentThickness)
        .shadow(color: segments[0] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[0] ? 4 : 0)
        .offset(y: -height * 0.38)

      // Segment b (top right vertical)
      SegmentShape(isHorizontal: false)
        .fill(segments[1] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentThickness, height: segmentLength * 0.85)
        .shadow(color: segments[1] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[1] ? 4 : 0)
        .offset(x: width * 0.28, y: -height * 0.18)

      // Segment c (bottom right vertical)
      SegmentShape(isHorizontal: false)
        .fill(segments[2] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentThickness, height: segmentLength * 0.85)
        .shadow(color: segments[2] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[2] ? 4 : 0)
        .offset(x: width * 0.28, y: height * 0.18)

      // Segment d (bottom horizontal)
      SegmentShape(isHorizontal: true)
        .fill(segments[3] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentLength, height: segmentThickness)
        .shadow(color: segments[3] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[3] ? 4 : 0)
        .offset(y: height * 0.38)

      // Segment e (bottom left vertical)
      SegmentShape(isHorizontal: false)
        .fill(segments[4] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentThickness, height: segmentLength * 0.85)
        .shadow(color: segments[4] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[4] ? 4 : 0)
        .offset(x: -width * 0.28, y: height * 0.18)

      // Segment f (top left vertical)
      SegmentShape(isHorizontal: false)
        .fill(segments[5] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentThickness, height: segmentLength * 0.85)
        .shadow(color: segments[5] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[5] ? 4 : 0)
        .offset(x: -width * 0.28, y: -height * 0.18)

      // Segment g (middle horizontal)
      SegmentShape(isHorizontal: true)
        .fill(segments[6] ? LEDColors.activeRed : LEDColors.dimRed)
        .frame(width: segmentLength, height: segmentThickness)
        .shadow(color: segments[6] ? LEDColors.activeRed.opacity(0.7) : .clear, radius: segments[6] ? 4 : 0)
    }
    .frame(width: width, height: height)
  }
}

struct SegmentShape: Shape {
  let isHorizontal: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()

    if isHorizontal {
      // Horizontal segment with pointed ends
      let pointOffset = rect.height * 0.5
      path.move(to: CGPoint(x: pointOffset, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - pointOffset, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.maxX - pointOffset, y: rect.maxY))
      path.addLine(to: CGPoint(x: pointOffset, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
    } else {
      // Vertical segment with pointed ends
      let pointOffset = rect.width * 0.5
      path.move(to: CGPoint(x: rect.midX, y: pointOffset))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - pointOffset))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - pointOffset))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.midX, y: pointOffset))
    }

    path.closeSubpath()
    return path
  }
}

// MARK: - Preview

#Preview {
  ZStack {
    Color(red: 0.95, green: 0.94, blue: 0.92)
      .ignoresSafeArea()

    SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 46.00,
      waitingDuration: 164,
      distanceMeters: 3300,
      isNight: true,
      topInset: 60
    )
    .frame(height: 450)
  }
}
