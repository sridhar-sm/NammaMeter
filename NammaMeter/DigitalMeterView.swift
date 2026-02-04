import SwiftUI

// MARK: - Digital Full Meter Panel

struct DigitalFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  @State private var glowPulse = false

  private let bezel = Color(red: 0.18, green: 0.2, blue: 0.24)
  private let accent = Color(red: 0.15, green: 0.8, blue: 0.9)

  var body: some View {
    MeterShell(style: .digital) { bodyWidth, bodyHeight in
      VStack(spacing: bodyHeight * 0.08) {
        Text("DIGITAL FARE METER")
          .font(.system(size: bodyWidth * 0.05, weight: .semibold, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.7))

        DigitalMeterScreen(tripState: tripState, fare: fare, glow: glowPulse, accent: accent, bezel: bezel)
          .frame(height: bodyHeight * 0.32)

        DigitalButtonRow(width: bodyWidth)
      }
      .padding(.horizontal, bodyWidth * 0.12)
      .padding(.vertical, bodyHeight * 0.12)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
        glowPulse = true
      }
    }
  }
}

// MARK: - Digital Display Panel

struct DigitalDisplayPanel: View {
  let tripState: TripMeterState
  let fare: Double
  @State private var glowPulse = false

  private let bezel = Color(red: 0.2, green: 0.22, blue: 0.26)
  private let accent = Color(red: 0.15, green: 0.8, blue: 0.9)

  var body: some View {
    GeometryReader { geo in
      let padding = min(geo.size.width, geo.size.height) * 0.06
      let availableWidth = max(geo.size.width - padding * 2, 0)
      let availableHeight = max(geo.size.height - padding * 2, 0)
      let aspect: CGFloat = 3.4
      let width = min(availableWidth, availableHeight * aspect)
      let height = width / aspect

      ZStack {
        Color.clear
        DigitalMeterScreen(tripState: tripState, fare: fare, glow: glowPulse, accent: accent, bezel: bezel)
          .frame(width: width, height: height)
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
        glowPulse = true
      }
    }
  }
}

// MARK: - Digital Meter Screen

struct DigitalMeterScreen: View {
  let tripState: TripMeterState
  let fare: Double
  let glow: Bool
  let accent: Color
  let bezel: Color

  var body: some View {
    GeometryReader { geo in
      let textSize = min(geo.size.height * 0.55, 36)
      let glowColor = accent.opacity(glow ? 0.85 : 0.45)

      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color(red: 0.03, green: 0.06, blue: 0.08))
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(bezel, lineWidth: 2)
          )

        Text(displayText())
          .font(.system(size: textSize, weight: .bold, design: .monospaced))
          .foregroundStyle(glowColor)
          .shadow(color: glowColor, radius: glow ? 12 : 6, x: 0, y: 0)
          .tracking(textSize * 0.06)
      }
    }
  }

  private func displayText() -> String {
    switch tripState {
    case .forHire:
      return "HIRE"
    case .inProgress, .complete:
      return formattedFare()
    }
  }

  private func formattedFare() -> String {
    let value = max(0, Int(fare.rounded()))
    return String(format: "%04d", value)
  }
}

// MARK: - Digital Button Row

struct DigitalButtonRow: View {
  let width: CGFloat

  var body: some View {
    HStack(spacing: width * 0.07) {
      ForEach(0..<3) { index in
        Circle()
          .fill(Color(red: 0.18, green: 0.19, blue: 0.22))
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.12), lineWidth: 1)
          )
          .frame(width: width * 0.08, height: width * 0.08)
          .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
          .opacity(index == 1 ? 1 : 0.85)
      }
    }
  }
}
