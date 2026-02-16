import SwiftUI

// MARK: - Main Panel

struct GoldenEagleFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  let isNight: Bool
  let topInset: CGFloat
  var cityVehicleLabel: String = ""

  var body: some View {
    MeterShell(style: .goldenEagle, topInset: topInset) { bodyWidth, bodyHeight in
      VStack(spacing: 0) {
        Spacer()

        // Display dial - shows fare, distance, wait time with LED segments
        GoldenEagleDisplayWindow(
          tripState: tripState,
          fare: fare,
          waitingDuration: waitingDuration,
          distanceKm: distanceMeters / 1000,
          isNight: isNight,
          width: bodyWidth * 0.90,
          height: bodyHeight * 0.62
        )

        Spacer(minLength: bodyHeight * 0.01)

        // Manufacturer plate - shows company info at bottom
        GoldenEagleManufacturerPlate(width: bodyWidth * 0.90, height: bodyHeight * 0.16)

        if !cityVehicleLabel.isEmpty {
          MeterCityVehicleLabel(text: cityVehicleLabel, fontSize: bodyHeight * 0.03)
            .padding(.top, bodyHeight * 0.01)
        }

        Spacer()
      }
    }
  }
}

// MARK: - Display Window

struct GoldenEagleDisplayWindow: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceKm: Double
  let isNight: Bool
  let width: CGFloat
  let height: CGFloat

  // Perforated face colors
  private let faceColor = MeterColorSchemes.GoldenEagle.face
  private let dotColor = MeterColorSchemes.GoldenEagle.dot

  // Row background colors (from real meter)
  private let fareRowColor = MeterColorSchemes.GoldenEagle.fareRow
  private let distRowColor = MeterColorSchemes.GoldenEagle.distRow
  private let waitRowColor = MeterColorSchemes.GoldenEagle.waitRow

  private var ledScheme: LEDColorScheme {
    let active = MeterColorSchemes.GoldenEagle.ledActive(isNight: isNight)
    let dim = MeterColorSchemes.GoldenEagle.ledDim
    return LEDColorScheme(active: active, dim: dim)
  }

  var body: some View {
    ZStack {
      // Layer 1: Dial bezel - dark gray border creating inset effect for the display dial
      RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
        .fill(MeterColorSchemes.GoldenEagle.caseEdge)
        .shadow(color: Color.black.opacity(0.4), radius: 3, x: 2, y: 2)

      // Layer 2: Perforated face - dotted texture background visible on real meter
      PerforatedBackground(baseColor: faceColor, dotColor: dotColor)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.03, style: .continuous))
        .padding(width * 0.015)

      // Layer 3: Content layout using GeometryReader for precise positioning
      GeometryReader { geo in
        let w = geo.size.width
        let h = geo.size.height
        let margin = w * 0.02

        // Horizontal layout calculations
        let leftMargin = margin * 2
        let rightMargin = margin * 3
        let textGap = margin * 0.5
        let textBlockWidth = w * 0.12

        let textRightEdge = w - rightMargin
        let textLeftEdge = textRightEdge - textBlockWidth
        let panelRightEdge = textLeftEdge - textGap
        let panelLeftEdge = leftMargin
        let panelWidth = max(panelRightEdge - panelLeftEdge, w * 0.36)
        let bottomPanelWidth = panelWidth * 0.82

        // Vertical layout calculations
        let fareHeight = h * 0.26
        let infoHeight = h * 0.21
        let rowSpacing = h * 0.04
        let totalRowsHeight = fareHeight + infoHeight + infoHeight + (rowSpacing * 2)
        let topPadding = max((h - totalRowsHeight) * 0.5, margin)
        let fareY = topPadding
        let distY = fareY + fareHeight + rowSpacing
        let waitY = distY + infoHeight + rowSpacing

        // Center positions for LED panels
        let panelCenterX = panelLeftEdge + panelWidth * 0.5
        let bottomPanelCenterX = panelRightEdge - bottomPanelWidth * 0.5

        // Time label positioning (left side of wait row)
        let timeLabelInset = margin
        let timeLabelWidth = max(panelLeftEdge - timeLabelInset, w * 0.14)
        let timeLabelCenterX = timeLabelInset + timeLabelWidth * 0.5

        ZStack(alignment: .topLeading) {
          // Row background 1: Fare row - dark maroon/red band
          RoundedRectangle(cornerRadius: fareHeight * 0.15, style: .continuous)
            .fill(fareRowColor)
            .frame(width: w - margin * 2, height: fareHeight)
            .position(x: w * 0.5, y: fareY + fareHeight * 0.5)

          // Row background 2: Distance row - dark green band
          RoundedRectangle(cornerRadius: infoHeight * 0.15, style: .continuous)
            .fill(distRowColor)
            .frame(width: w - margin * 2, height: infoHeight)
            .position(x: w * 0.5, y: distY + infoHeight * 0.5)

          // Row background 3: Wait time row - dark teal band
          RoundedRectangle(cornerRadius: infoHeight * 0.15, style: .continuous)
            .fill(waitRowColor)
            .frame(width: w - margin * 2, height: infoHeight)
            .position(x: w * 0.5, y: waitY + infoHeight * 0.5)

          // LED panel 1: Fare display - shows rupees and paise
          GoldenEagleFareRow(
            tripState: tripState,
            fare: fare,
            width: panelWidth,
            height: fareHeight,
            ledScheme: ledScheme
          )
          .position(x: panelCenterX, y: fareY + fareHeight * 0.5)

          // LED panel 2: Distance display - shows kilometers
          GoldenEagleDistanceRow(
            tripState: tripState,
            distanceKm: distanceKm,
            width: panelWidth,
            height: infoHeight,
            ledScheme: ledScheme
          )
          .position(x: panelCenterX, y: distY + infoHeight * 0.5)

          // LED panel 3: Wait time display - shows minutes:seconds
          GoldenEagleWaitRow(
            tripState: tripState,
            waitingDuration: waitingDuration,
            width: bottomPanelWidth,
            height: infoHeight,
            ledScheme: ledScheme
          )
          .position(x: bottomPanelCenterX, y: waitY + infoHeight * 0.5)

          // Label 1: "FARE / Rs." - right side of fare row
          GoldenEagleDialLabel(
            title: "FARE",
            subtitle: "Rs.",
            width: textBlockWidth,
            height: fareHeight,
            alignment: .leading,
            lightText: true
          )
          .position(x: textLeftEdge + textBlockWidth * 0.5, y: fareY + fareHeight * 0.5)

          // Label 2: "Dist. / Km." - right side of distance row
          GoldenEagleDialLabel(
            title: "Dist.",
            subtitle: "Km.",
            width: textBlockWidth,
            height: infoHeight,
            alignment: .leading,
            lightText: true
          )
          .position(x: textLeftEdge + textBlockWidth * 0.5, y: distY + infoHeight * 0.5)

          // Label 3: "Time / Wait Time" - left side of wait row
          GoldenEagleDialLabel(
            title: "Time",
            subtitle: "Wait Time",
            width: timeLabelWidth,
            height: infoHeight,
            alignment: .leading,
            lightText: true
          )
          .position(x: timeLabelCenterX, y: waitY + infoHeight * 0.5)

          // Badge: Golden Eagle company logo - bottom right of wait row
          GoldenEagleBadge(width: w * 0.17, height: h * 0.24)
            .position(
              x: w - (w * 0.17) * 0.5 - rightMargin * 0.4,
              y: waitY + infoHeight * 0.5
            )
        }
      }
    }
    .frame(width: width, height: height)
  }
}

// MARK: - Rows

struct GoldenEagleFareRow: View {
  let tripState: TripMeterState
  let fare: Double
  let width: CGFloat
  let height: CGFloat
  let ledScheme: LEDColorScheme

  var body: some View {
    GoldenEagleDigitField(width: width, height: height, widthFactor: 3.5) { digitHeight in
      if tripState == .forHire {
        GoldenEagleBlankFareDisplay(digitHeight: digitHeight, colorScheme: ledScheme)
      } else {
        FareDigitsDisplay(fare: fare, digitHeight: digitHeight, colorScheme: ledScheme)
      }
    }
  }
}

struct GoldenEagleDistanceRow: View {
  let tripState: TripMeterState
  let distanceKm: Double
  let width: CGFloat
  let height: CGFloat
  let ledScheme: LEDColorScheme

  var body: some View {
    GoldenEagleDigitField(width: width, height: height, widthFactor: 2.8) { digitHeight in
      if tripState == .forHire {
        GoldenEagleHireDistanceDisplay(digitHeight: digitHeight, colorScheme: ledScheme)
      } else {
        DistanceDisplay(
          distanceKm: distanceKm,
          digitHeight: digitHeight,
          showBlank: false,
          showForHire: false,
          colorScheme: ledScheme
        )
      }
    }
  }
}

struct GoldenEagleWaitRow: View {
  let tripState: TripMeterState
  let waitingDuration: TimeInterval
  let width: CGFloat
  let height: CGFloat
  let ledScheme: LEDColorScheme

  var body: some View {
    GoldenEagleDigitField(width: width, height: height, widthFactor: 2.85) { digitHeight in
      WaitTimeDisplay(
        duration: waitingDuration,
        digitHeight: digitHeight,
        showBlank: tripState == .forHire,
        showForHire: false,
        colorScheme: ledScheme
      )
    }
  }
}

struct GoldenEagleBlankFareDisplay: View {
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .green

  var body: some View {
    let blanks = Array(repeating: LED7SegmentValue.blank, count: 3)
    let paiseBlanks = Array(repeating: LED7SegmentValue.blank, count: 2)

    return HStack(spacing: digitHeight * 0.12) {
      LEDDigitGroup(
        digitCount: 3,
        height: digitHeight,
        colorScheme: colorScheme,
        decimalPosition: 2,
        values: blanks
      )

      LEDDigitGroup(
        digitCount: 2,
        height: digitHeight,
        colorScheme: colorScheme,
        values: paiseBlanks
      )
    }
  }
}

struct GoldenEagleHireDistanceDisplay: View {
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .green

  var body: some View {
    let values: [LED7SegmentValue] = [
      .character("H"),
      .character("I"),
      .character("r")
    ]

    return HStack(spacing: digitHeight * 0.08) {
      LEDDigitGroup(
        digitCount: 3,
        height: digitHeight,
        colorScheme: colorScheme,
        isSmall: true,
        values: values
      )

      LEDDecimalPoint(isActive: false, colorScheme: colorScheme, size: digitHeight * 0.08)
        .offset(y: digitHeight * 0.35)

      LED7SegmentDigit(
        value: .character("E"),
        height: digitHeight,
        colorScheme: colorScheme,
        isSmall: true
      )
    }
  }
}

// MARK: - Components

struct GoldenEagleDigitField<Content: View>: View {
  let width: CGFloat
  let height: CGFloat
  let widthFactor: CGFloat
  let content: (CGFloat) -> Content

  private let dialTop = MeterColorSchemes.GoldenEagle.dialTop
  private let dialBottom = MeterColorSchemes.GoldenEagle.dialBottom
  private let dialEdge = MeterColorSchemes.GoldenEagle.dialEdge

  init(width: CGFloat, height: CGFloat, widthFactor: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) {
    self.width = width
    self.height = height
    self.widthFactor = widthFactor
    self.content = content
  }

  var body: some View {
    RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
      .fill(
        LinearGradient(
          colors: [dialTop, dialBottom],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
          .stroke(dialEdge.opacity(0.7), lineWidth: 1)
      )
      .frame(width: width, height: height)
      .overlay(
        GeometryReader { geo in
          let digitHeight = min(geo.size.height * 0.82, geo.size.width / widthFactor)
          content(digitHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      )
  }
}

struct GoldenEagleDialLabel: View {
  let title: String
  let subtitle: String
  let width: CGFloat
  let height: CGFloat
  let alignment: HorizontalAlignment
  var lightText: Bool = false

  var body: some View {
    let titleSize = height * 0.24
    let subtitleSize = height * 0.18
    let textAlignment = Alignment(horizontal: alignment, vertical: .center)
    let textColor = lightText ? Color.white.opacity(0.9) : Color.black.opacity(0.75)

    return VStack(alignment: alignment, spacing: height * 0.05) {
      Text(title)
        .font(.system(size: titleSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(subtitle)
        .font(.system(size: subtitleSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .foregroundStyle(textColor)
    .frame(width: width, height: height, alignment: textAlignment)
  }
}

struct GoldenEagleLabelBadge: View {
  let title: String
  let subtitle: String
  let width: CGFloat
  let height: CGFloat
  let accent: Color

  var body: some View {
    let titleSize = height * 0.26
    let subtitleSize = height * 0.2

    VStack(alignment: .leading, spacing: height * 0.04) {
      Text(title)
        .font(.system(size: titleSize, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(subtitle)
        .font(.system(size: subtitleSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .foregroundStyle(Color.black.opacity(0.85))
    .padding(.leading, width * 0.1)
    .frame(width: width, height: height, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
        .fill(
          LinearGradient(
            colors: [accent.opacity(0.9), accent.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
            .stroke(Color.black.opacity(0.4), lineWidth: 0.8)
        )
    )
  }
}

struct GoldenEagleBadge: View {
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
        .fill(MeterColorSchemes.GoldenEagle.accentBlue)
        .overlay(
          RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
        )

      VStack(spacing: height * 0.05) {
        Text("GOLDEN")
          .font(.system(size: height * 0.16, weight: .bold, design: .rounded))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        ZStack {
          Circle()
            .fill(MeterColorSchemes.GoldenEagle.accentGold)
          Text("GE")
            .font(.system(size: height * 0.18, weight: .heavy, design: .rounded))
            .foregroundStyle(MeterColorSchemes.GoldenEagle.accentBlue)
        }
        .frame(width: width * 0.45, height: width * 0.45)
        Text("EAGLE")
          .font(.system(size: height * 0.16, weight: .bold, design: .rounded))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      .foregroundStyle(Color.white)
    }
    .frame(width: width, height: height)
  }
}

// MARK: - Manufacturer Plate

struct GoldenEagleManufacturerPlate: View {
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    ZStack {
      // Inset bezel effect
      RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
        .fill(MeterColorSchemes.GoldenEagle.caseEdge)
        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 1, y: 1)

      // Main plate background (inset)
      RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color.black.opacity(0.85), Color.black.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: height * 0.2, style: .continuous)
            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
        )
        .padding(width * 0.012)

      HStack {
        PlateScrew(size: height * 0.28)
        Spacer()
        PlateScrew(size: height * 0.28)
      }
      .padding(.horizontal, width * 0.08)

      VStack(spacing: height * 0.12) {
        Text("Mfd by Golden Eagle Enterprises, Bengaluru")
          .font(.system(size: height * 0.16, weight: .semibold, design: .rounded))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text("Auto/Taxi Fare Meter Model Approval No. IND/09/16/324")
          .font(.system(size: height * 0.12, weight: .medium, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.75))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
      .foregroundStyle(Color.white.opacity(0.85))
      .padding(.horizontal, width * 0.12)
    }
    .frame(width: width, height: height)
  }
}

struct PlateScrew: View {
  let size: CGFloat

  var body: some View {
    Circle()
      .fill(MeterColorSchemes.GoldenEagle.caseLight)
      .overlay(
        Circle()
          .stroke(Color.black.opacity(0.6), lineWidth: 1)
      )
      .frame(width: size, height: size)
  }
}

// MARK: - Preview

#Preview {
  ZStack {
    MeterColorSchemes.Metal.highlight
      .ignoresSafeArea()

    GoldenEagleFullMeterPanel(
      tripState: .inProgress,
      fare: 30.5,
      waitingDuration: 132,
      distanceMeters: 2100,
      isNight: false,
      topInset: 60
    )
    .frame(height: 460)
  }
}

// MARK: - Perforated Background

struct PerforatedBackground: View {
  let baseColor: Color
  let dotColor: Color

  var body: some View {
    GeometryReader { geo in
      let dotSpacing: CGFloat = 6
      let dotSize: CGFloat = 2

      ZStack {
        baseColor

        Canvas { context, _ in
          let rows = Int(geo.size.height / dotSpacing) + 1
          let cols = Int(geo.size.width / dotSpacing) + 1

          for row in 0..<rows {
            for col in 0..<cols {
              let x = CGFloat(col) * dotSpacing + dotSpacing * 0.5
              let y = CGFloat(row) * dotSpacing + dotSpacing * 0.5
              let rect = CGRect(x: x - dotSize * 0.5, y: y - dotSize * 0.5, width: dotSize, height: dotSize)
              context.fill(Circle().path(in: rect), with: .color(dotColor.opacity(0.4)))
            }
          }
        }
      }
    }
  }
}
