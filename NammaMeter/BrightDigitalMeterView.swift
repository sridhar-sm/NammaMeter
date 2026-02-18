import SwiftUI

// MARK: - Main Panel

struct BrightDigitalFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  var cityVehicleLabel: String = ""

  private let faceTop = MeterColorSchemes.BrightDigital.faceTop
  private let faceBottom = MeterColorSchemes.BrightDigital.faceBottom

  var body: some View {
    MeterShell(style: .brightDigital) { bodyWidth, bodyHeight in
      let faceWidth = bodyWidth * 0.92
      let faceHeight = bodyHeight * 0.86
      let windowWidth = faceWidth * 0.96
      let windowHeight = faceHeight * 0.68
      let badgeWidth = faceWidth * 0.84
      let badgeHeight = faceHeight * 0.14

      ZStack {
        RoundedRectangle(cornerRadius: bodyWidth * 0.06, style: .continuous)
          .fill(
            LinearGradient(
              colors: [faceTop, faceBottom],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: faceWidth, height: faceHeight)
          .overlay(
            RoundedRectangle(cornerRadius: bodyWidth * 0.06, style: .continuous)
              .stroke(Color.white.opacity(0.06), lineWidth: 1)
          )

        VStack(spacing: faceHeight * 0.03) {
          Spacer(minLength: faceHeight * 0.04)
          BrightDigitalDisplayWindow(
            tripState: tripState,
            fare: fare,
            waitingDuration: waitingDuration,
            distanceKm: distanceMeters / 1000,
            width: windowWidth,
            height: windowHeight
          )
          BrightDigitalBadge(width: badgeWidth, height: badgeHeight)
          if !cityVehicleLabel.isEmpty {
            MeterCityVehicleLabel(text: cityVehicleLabel, fontSize: faceHeight * 0.045)
          }
          Spacer(minLength: faceHeight * 0.04)
        }
        .frame(width: faceWidth, height: faceHeight)
      }
    }
  }
}

// MARK: - Display Window

struct BrightDigitalDisplayWindow: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceKm: Double
  let width: CGFloat
  let height: CGFloat

  private let windowBackground = MeterColorSchemes.BrightDigital.windowBackground
  private let lineColor = MeterColorSchemes.BrightDigital.line
  private let labelColor = MeterColorSchemes.BrightDigital.label
  private let ledScheme = LEDColorScheme.red

  var body: some View {
    let lineWidth = max(1, width * 0.003)
    let cornerRadius = width * 0.02
    let inset = width * 0.015
    let contentWidth = width - inset * 2
    let contentHeight = height - inset * 2
    let rowHeight = contentHeight * 0.27
    let dividerTotal = lineWidth * 3
    let labelStripHeight = max(0, contentHeight - rowHeight * 3 - dividerTotal)
    let panelHeight = rowHeight * 0.7
    let innerCornerRadius = max(2, cornerRadius - inset * 0.3)

    let farePanelWidth = panelWidth(digitCount: 5, scale: 1.0, spacingFactor: 0.12, panelHeight: panelHeight)
    let distancePanelWidth = panelWidth(
      digitCount: 4,
      scale: 1.0,
      spacingFactor: 0.12,
      panelHeight: panelHeight,
      decimalExtra: true
    )
    let waitDigitHeight = digitHeight(panelHeight: panelHeight, scale: 0.82)
    let waitDigitWidth = waitDigitHeight * 0.6
    let waitSpacing = waitDigitHeight * 0.08
    let waitGroupWidth = waitDigitWidth * 2 + waitSpacing
    let waitPanelWidth = waitGroupWidth * 2 + waitSpacing * 2 + waitDigitHeight * 0.1

    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(windowBackground)

      VStack(spacing: 0) {
        BrightDigitalRow(
          leftLabel: "Rs.",
          rightLabel: "Rs.",
          rowWidth: contentWidth,
          rowHeight: rowHeight,
          panelWidth: farePanelWidth,
          labelColor: labelColor,
          digitScale: 1.0
        ) { digitHeight in
          BrightDigitalFareDisplay(
            tripState: tripState,
            fare: fare,
            digitHeight: digitHeight,
            colorScheme: ledScheme
          )
        }

        Rectangle()
          .fill(lineColor)
          .frame(height: lineWidth)

        BrightDigitalRow(
          leftLabel: "Distance",
          rightLabel: "Kms",
          rowWidth: contentWidth,
          rowHeight: rowHeight,
          panelWidth: distancePanelWidth,
          labelColor: labelColor,
          digitScale: 1.0
        ) { digitHeight in
          BrightDigitalDistanceDisplay(
            tripState: tripState,
            distanceKm: distanceKm,
            digitHeight: digitHeight,
            colorScheme: ledScheme
          )
        }

        Rectangle()
          .fill(lineColor)
          .frame(height: lineWidth)

        BrightDigitalRow(
          leftLabel: "Waiting",
          rightLabel: "Time",
          rowWidth: contentWidth,
          rowHeight: rowHeight,
          panelWidth: waitPanelWidth,
          labelColor: labelColor,
          digitScale: 0.82
        ) { digitHeight in
          BrightDigitalWaitDisplay(
            tripState: tripState,
            waitingDuration: waitingDuration,
            digitHeight: digitHeight,
            colorScheme: ledScheme
          )
        }

        Rectangle()
          .fill(lineColor)
          .frame(height: lineWidth)

        BrightDigitalNameStrip(width: contentWidth, height: max(labelStripHeight, contentHeight * 0.16))
      }
      .frame(width: contentWidth, height: contentHeight, alignment: .top)
      .offset(x: inset, y: inset)
      .clipShape(RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous))

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(Color.black.opacity(0.35), lineWidth: lineWidth)

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.35), Color.black.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: lineWidth
        )

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.25),
              Color.white.opacity(0.08),
              Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    }
    .frame(width: width, height: height)
  }

  private func digitHeight(panelHeight: CGFloat, scale: CGFloat) -> CGFloat {
    panelHeight * 0.78 * scale
  }

  private func panelWidth(
    digitCount: Int,
    scale: CGFloat,
    spacingFactor: CGFloat,
    panelHeight: CGFloat,
    decimalExtra: Bool = false
  ) -> CGFloat {
    let height = digitHeight(panelHeight: panelHeight, scale: scale)
    let digitWidth = height * 0.6
    let spacing = height * spacingFactor
    let base = digitWidth * CGFloat(digitCount) + spacing * CGFloat(max(digitCount - 1, 0))
    let decimal = decimalExtra ? height * 0.12 : 0
    return base + decimal
  }
}

struct BrightDigitalRow<Content: View>: View {
  let leftLabel: String
  let rightLabel: String
  let rowWidth: CGFloat
  let rowHeight: CGFloat
  let panelWidth: CGFloat
  let labelColor: Color
  let digitScale: CGFloat
  let content: (CGFloat) -> Content

  var body: some View {
    let fontSize = rowHeight * 0.26
    let panelHeight = rowHeight * 0.7

    ZStack {
      BrightDigitalLEDPanel(width: panelWidth, height: panelHeight, digitScale: digitScale) { digitHeight in
        content(digitHeight)
      }

      HStack {
        Text(leftLabel)
          .font(.system(size: fontSize, weight: .semibold, design: .rounded))
          .foregroundStyle(labelColor)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        Spacer()

        Text(rightLabel)
          .font(.system(size: fontSize, weight: .semibold, design: .rounded))
          .foregroundStyle(labelColor)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      .padding(.horizontal, rowWidth * 0.03)
    }
    .frame(width: rowWidth, height: rowHeight)
  }
}

struct BrightDigitalLEDPanel<Content: View>: View {
  let width: CGFloat
  let height: CGFloat
  let digitScale: CGFloat
  let content: (CGFloat) -> Content

  private let panelTop = MeterColorSchemes.BrightDigital.panelTop
  private let panelBottom = MeterColorSchemes.BrightDigital.panelBottom
  private let panelEdge = MeterColorSchemes.BrightDigital.panelEdge

  var body: some View {
    RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
      .fill(
        LinearGradient(
          colors: [panelTop, panelBottom],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
          .stroke(panelEdge.opacity(0.7), lineWidth: 1)
      )
      .frame(width: width, height: height)
      .overlay(
        GeometryReader { geo in
          let digitHeight = geo.size.height * 0.78 * digitScale
          content(digitHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      )
  }
}

struct BrightDigitalFareDisplay: View {
  let tripState: TripMeterState
  let fare: Double
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .red

  var body: some View {
    if tripState == .forHire {
      let values: [LED7SegmentValue] = [.blank, .character("F"), .character("o"), .character("r"), .blank]
      LEDDigitGroup(
        digitCount: 5,
        height: digitHeight,
        colorScheme: colorScheme,
        values: values
      )
    } else {
      let value = max(0, Int(fare.rounded()))
      LEDDigitGroup.forInteger(
        value,
        digitCount: 5,
        height: digitHeight,
        colorScheme: colorScheme,
        leadingZeroBlanking: true
      )
    }
  }
}

struct BrightDigitalDistanceDisplay: View {
  let tripState: TripMeterState
  let distanceKm: Double
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .red

  var body: some View {
    if tripState == .forHire {
      let values: [LED7SegmentValue] = [.character("H"), .character("I"), .character("r"), .character("E")]
      LEDDigitGroup(
        digitCount: 4,
        height: digitHeight,
        colorScheme: colorScheme,
        values: values
      )
    } else {
      let value = max(0, Int((distanceKm * 100).rounded()))
      LEDDigitGroup.forInteger(
        value,
        digitCount: 4,
        height: digitHeight,
        colorScheme: colorScheme,
        leadingZeroBlanking: true,
        decimalPosition: 1
      )
    }
  }
}

struct BrightDigitalWaitDisplay: View {
  let tripState: TripMeterState
  let waitingDuration: TimeInterval
  let digitHeight: CGFloat
  var colorScheme: LEDColorScheme = .red

  var body: some View {
    WaitTimeDisplay(
      duration: waitingDuration,
      digitHeight: digitHeight,
      showBlank: tripState == .forHire,
      showForHire: false,
      colorScheme: colorScheme
    )
  }
}

struct BrightDigitalNameStrip: View {
  let width: CGFloat
  let height: CGFloat

  private let textColor = MeterColorSchemes.BrightDigital.text

  var body: some View {
    ZStack {
      Color.white.opacity(0.9)
      Text("Bright Digital Fare Meter")
        .font(.system(size: height * 0.45, weight: .semibold, design: .rounded))
        .foregroundStyle(textColor)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
    .frame(width: width, height: height)
  }
}

// MARK: - Badge

struct BrightDigitalBadge: View {
  let width: CGFloat
  let height: CGFloat

  private let badgeTop = MeterColorSchemes.BrightDigital.badgeTop
  private let badgeBottom = MeterColorSchemes.BrightDigital.badgeBottom

  var body: some View {
    RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
      .fill(
        LinearGradient(
          colors: [badgeTop, badgeBottom],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
          .stroke(Color.white.opacity(0.4), lineWidth: 1)
      )
      .frame(width: width, height: height)
      .overlay(
        VStack(spacing: height * 0.12) {
          Text("Bright Digital Fare Meter Auto Rickshaw")
            .font(.system(size: height * 0.28, weight: .semibold, design: .rounded))
          Text("MFD BY: Bangalore Auto Mobiles")
            .font(.system(size: height * 0.22, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Color.white.opacity(0.95))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(.horizontal, width * 0.04)
      )
  }
}
