import SwiftUI

// MARK: - Super Full Meter Panel

struct SuperFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let digitStyle: DigitWheelStyle
  let topInset: CGFloat
  @State private var hirePulse = false

  private let caseTop = MeterColorSchemes.SuperMechanical.caseTop
  private let caseBottom = MeterColorSchemes.SuperMechanical.caseBottom
  private let metalPanel = MeterColorSchemes.SuperMechanical.metalPanel
  private let metalEdge = MeterColorSchemes.SuperMechanical.metalEdge
  private let displayEdge = MeterColorSchemes.SuperMechanical.displayEdge
  private let printInk = MeterColorSchemes.SuperMechanical.printInk

  var body: some View {
    GeometryReader { geo in
      // Calculate meter dimensions using shared constants
      let desiredBodyWidth = max(geo.size.width * SuperMeterDimensions.widthRatio, 0)
      let bodyHeightForWidth = desiredBodyWidth * SuperMeterDimensions.bodyAspect
      let canopyHeightForWidth = bodyHeightForWidth * SuperMeterDimensions.canopyRatio
      // Base disabled - uncomment to re-enable
      // let baseHeightForWidth = bodyHeightForWidth * SuperMeterDimensions.baseRatio
      let totalHeightForWidth = bodyHeightForWidth + canopyHeightForWidth * SuperMeterDimensions.canopyOverlap
      // With base: let totalHeightForWidth = bodyHeightForWidth + canopyHeightForWidth * SuperMeterDimensions.canopyOverlap + baseHeightForWidth

      // Scale to fit available height
      let rawScale = totalHeightForWidth > 0 ? geo.size.height / totalHeightForWidth : 0
      let scale = rawScale.isFinite ? min(1, max(rawScale, 0)) : 0
      let bodyWidth = desiredBodyWidth * scale
      let bodyHeight = bodyHeightForWidth * scale
      let canopyHeight = canopyHeightForWidth * scale
      // Base disabled - uncomment to re-enable
      // let baseHeight = baseHeightForWidth * scale

      // Position meter so canopy bottom aligns with MeterShell top (at topInset)
      let meterTopOffset = max(topInset - canopyHeight, 0.0)

      ZStack(alignment: .top) {
        VStack(spacing: -bodyHeight * 0.08) {
          // Canopy with original proportions
          SuperMeterCanopyShape()
            .fill(
              LinearGradient(
                colors: [caseTop, caseBottom],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: bodyWidth * 0.9, height: canopyHeight)
            .overlay(
              SuperMeterCanopyShape()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)

          // Main meter body
          ZStack {
            // Outer casing
            RoundedRectangle(cornerRadius: bodyWidth * 0.1, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [caseTop, caseBottom],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: bodyWidth * 0.1, style: .continuous)
                  .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
              )
              .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 10)

            // Inner white panel - wider than tall (landscape rectangle)
            RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous)
              .fill(metalPanel)
              .padding(.horizontal, bodyWidth * 0.07)
              .padding(.top, bodyHeight * 0.07)
              .padding(.bottom, bodyHeight * 0.4)
              .overlay(
                RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous)
                  .stroke(metalEdge, lineWidth: 1)
                  .padding(.horizontal, bodyWidth * 0.07)
                  .padding(.top, bodyHeight * 0.07)
                  .padding(.bottom, bodyHeight * 0.4)
              )

            // Dial face content
            SuperMeterFace(
              bodyWidth: bodyWidth,
              bodyHeight: bodyHeight,
              tripState: tripState,
              fare: fare,
              displayEdge: displayEdge,
              printInk: printInk,
              pulse: hirePulse,
              digitStyle: digitStyle
            )
            .padding(.horizontal, bodyWidth * 0.07)
            .padding(.top, bodyHeight * 0.07)
            .padding(.bottom, bodyHeight * 0.4)
            .clipShape(RoundedRectangle(cornerRadius: bodyWidth * 0.07, style: .continuous))

            // Manufacturer plate
            SuperMeterPlate(bodyWidth: bodyWidth, bodyHeight: bodyHeight, printInk: printInk, metalPanel: metalPanel, metalEdge: metalEdge)
              .offset(y: bodyHeight * 0.25)
          }
          .frame(width: bodyWidth, height: bodyHeight)

          // Base mount - DISABLED (uncomment to re-enable)
          // SuperMeterBaseView(width: bodyWidth * 0.62, height: baseHeight)
          //   .offset(y: baseHeight * -0.05)
        }
        .offset(y: meterTopOffset)
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
      // DEBUG: Temporary border to visualize Super Mechanical meter bounds (uncomment for debugging)
      // .overlay(
      //   Rectangle()
      //     .stroke(Color.blue, lineWidth: 2)
      // )
    }
    .hirePulse(tripState: tripState, pulse: $hirePulse)
  }
}

// MARK: - Super Meter Canopy Shape

/// Classic peaked canopy shape for the meter top
struct SuperMeterCanopyShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let peak = CGPoint(x: rect.midX, y: rect.minY)
    let leftTop = CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.35)
    let rightTop = CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.35)

    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: leftTop)
    path.addQuadCurve(to: peak, control: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY))
    path.addQuadCurve(to: rightTop, control: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

// MARK: - Super Display Panel

struct SuperDisplayPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let digitStyle: DigitWheelStyle
  @State private var hirePulse = false

  private let displayEdge = MeterColorSchemes.SuperMechanical.displayEdge

  var body: some View {
    GeometryReader { geo in
      let padding = min(geo.size.width, geo.size.height) * 0.06
      let availableWidth = max(geo.size.width - padding * 2, 0)
      let availableHeight = max(geo.size.height - padding * 2, 0)
      let aspect: CGFloat = 3.2
      let width = min(availableWidth, availableHeight * aspect)
      let height = width / aspect

      ZStack {
        Color.clear
        MeterDisplayWindow(
          tripState: tripState,
          fare: fare,
          displayEdge: displayEdge,
          pulse: hirePulse,
          digitStyle: digitStyle
        )
        .frame(width: width, height: height)
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .hirePulse(tripState: tripState, pulse: $hirePulse)
  }
}

// MARK: - Super Meter Face

struct SuperMeterFace: View {
  let bodyWidth: CGFloat
  let bodyHeight: CGFloat
  let tripState: TripMeterState
  let fare: Double
  let displayEdge: Color
  let printInk: Color
  let pulse: Bool
  let digitStyle: DigitWheelStyle

  var body: some View {
    // Face layering: title -> subtitle -> display window -> RUPEES/FARE/PAISE row.
    VStack(spacing: bodyHeight * 0.008) {
      Text("Super")
        .font(.system(size: bodyWidth * 0.07, weight: .bold, design: .rounded))
        .foregroundStyle(printInk)

      Text("AUTO RICKSHAW METER")
        .font(.system(size: bodyWidth * 0.038, weight: .semibold, design: .rounded))
        .foregroundStyle(printInk.opacity(0.75))

      MeterDisplayWindow(
        tripState: tripState,
        fare: fare,
        displayEdge: displayEdge,
        pulse: pulse,
        digitStyle: digitStyle
      )
      .frame(height: bodyHeight * 0.2)

      HStack(spacing: bodyWidth * 0.03) {
        Text("RUPEES")
          .font(.system(size: bodyWidth * 0.038, weight: .semibold, design: .rounded))
          .tracking(1.2)
        Text("FARE")
          .font(.system(size: bodyWidth * 0.08, weight: .heavy, design: .rounded))
          .foregroundStyle(MeterColorSchemes.SuperMechanical.accentRed)
          .tracking(1.0)
        Text("PAISE")
          .font(.system(size: bodyWidth * 0.038, weight: .semibold, design: .rounded))
          .tracking(1.2)
      }
      .foregroundStyle(printInk.opacity(0.7))
    }
    .padding(.horizontal, bodyWidth * 0.03)
  }
}

// MARK: - Super Meter Plate

struct SuperMeterPlate: View {
  let bodyWidth: CGFloat
  let bodyHeight: CGFloat
  let printInk: Color
  let metalPanel: Color
  let metalEdge: Color

  var body: some View {
    RoundedRectangle(cornerRadius: bodyWidth * 0.03, style: .continuous)
      .fill(
        LinearGradient(
          colors: [Color.white, metalPanel, metalEdge],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: bodyWidth * 0.03, style: .continuous)
          .stroke(Color.black.opacity(0.4), lineWidth: 0.8)
      )
      .frame(width: bodyWidth * 0.7, height: bodyHeight * 0.2)
      .overlay(
        VStack(spacing: bodyHeight * 0.012) {
          Text("Manufactured by")
            .font(.system(size: bodyWidth * 0.03, weight: .semibold, design: .rounded))
            .foregroundStyle(printInk.opacity(0.7))
          Text("Super METER MFG. CO.")
            .font(.system(size: bodyWidth * 0.04, weight: .bold, design: .rounded))
            .foregroundStyle(printInk)
          Text("MUNDHWA, PUNE · INDIA")
            .font(.system(size: bodyWidth * 0.028, weight: .medium, design: .rounded))
            .foregroundStyle(printInk.opacity(0.6))
        }
      )
  }
}

// MARK: - Super Meter Base View

struct SuperMeterBaseView: View {
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: height * 0.35, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              MeterColorSchemes.SuperMechanical.shadowTop,
              MeterColorSchemes.SuperMechanical.shadowBottom
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: height * 0.35, style: .continuous)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )

      HStack(spacing: width * 0.12) {
        Capsule()
          .fill(Color.black.opacity(0.7))
          .frame(width: width * 0.12, height: height * 0.55)
        Capsule()
          .fill(Color.black.opacity(0.7))
          .frame(width: width * 0.12, height: height * 0.55)
      }
    }
    .frame(width: width, height: height)
  }
}

// MARK: - Meter Display Window

struct MeterDisplayWindow: View {
  let tripState: TripMeterState
  let fare: Double
  let displayEdge: Color
  let pulse: Bool
  let digitStyle: DigitWheelStyle

  var body: some View {
    GeometryReader { geo in
      let textSize = min(geo.size.height * 0.55, 28)
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(MeterColorSchemes.SuperMechanical.displayBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(displayEdge, lineWidth: 2)
          )

        if tripState == .forHire {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(MeterColorSchemes.SuperMechanical.accentRed)
            .overlay(
              Text("FOR HIRE")
                .font(.system(size: textSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(textSize * 0.06)
            )
            .padding(.horizontal, 10)
            .opacity(pulse ? 0.7 : 1.0)
        } else {
          // Show fare for both inProgress and complete states
          let digitData = formattedDigits()
          MeterDigitsRow(
            digits: digitData.digits,
            paiseStartIndex: digitData.paiseStartIndex,
            digitStyle: digitStyle
          )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 30)
            .padding(.leading, 0)
        }
      }
    }
  }

  private func formattedDigits() -> (digits: [String], paiseStartIndex: Int) {
    let totalPaise = max(0, Int((fare * 100).rounded()))
    let rupees = totalPaise / 100
    let paise = totalPaise % 100
    let rupeesString = String(format: "%02d", rupees % 100)
    let paiseString = String(format: "%02d", paise)
    let combined = rupeesString + paiseString
    return (combined.map { String($0) }, rupeesString.count)
  }
}

// MARK: - Meter Digits Row

struct MeterDigitsRow: View {
  let digits: [String]
  let paiseStartIndex: Int
  let digitStyle: DigitWheelStyle

  var body: some View {
    GeometryReader { geo in
      let largeSpacing: CGFloat = 20
      let smallSpacing: CGFloat = 2
      let count = max(digits.count, 1)
      let maxDigitWidth = geo.size.width / CGFloat(count)
      let digitWidth = maxDigitWidth * 0.72
      let totalGap = (0..<(count - 1)).reduce(CGFloat(0)) { partial, index in
        partial + gapSpacing(after: index, large: largeSpacing, small: smallSpacing)
      }
      let rowWidth = (digitWidth * CGFloat(count)) + totalGap

      HStack(spacing: 0) {
        ForEach(Array(digits.enumerated()), id: \.offset) { index, value in
          MeterDigitCell(digit: value, isAccent: index >= paiseStartIndex, digitStyle: digitStyle)
            .frame(width: digitWidth, height: geo.size.height * 0.92)
            .padding(.trailing, index < count - 1
              ? gapSpacing(after: index, large: largeSpacing, small: smallSpacing)
              : 0
            )
        }
      }
      .frame(width: rowWidth, alignment: .center)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
  }

  private func gapSpacing(after index: Int, large: CGFloat, small: CGFloat) -> CGFloat {
    index >= paiseStartIndex ? small : large
  }
}

// MARK: - Meter Digit Cell

/// Wrapper for MechanicalDigitWheel that maintains the existing API.
/// All rendering and animation logic is now in MechanicalDigitWheel.
struct MeterDigitCell: View {
  let digit: String
  let isAccent: Bool
  let digitStyle: DigitWheelStyle

  var body: some View {
    MechanicalDigitWheel(
      digit: digit,
      isAccent: isAccent,
      digitStyle: digitStyle
    )
  }
}
