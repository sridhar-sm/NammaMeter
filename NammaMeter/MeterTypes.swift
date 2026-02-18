import SwiftUI
import UIKit

// MARK: - Meter Category

enum MeterCategory {
  case mechanical
  case electronic
}

// MARK: - Display Fields

enum MeterDisplayField {
  case fare
  case waitTime
  case distance
}

// MARK: - Status Indicators

enum MeterStatusIndicator {
  case forHire
  case hired
  case stop
  case nightMode
}

// MARK: - Meter Capabilities

struct MeterCapabilities {
  let category: MeterCategory
  let displayFields: Set<MeterDisplayField>
  let statusIndicators: Set<MeterStatusIndicator>

  var isMechanical: Bool { category == .mechanical }
  var showsWaitTime: Bool { displayFields.contains(.waitTime) }
  var showsDistance: Bool { displayFields.contains(.distance) }
}

// MARK: - Meter Face Style

enum MeterFaceStyle: String, CaseIterable, Identifiable {
  case superMeter = "Super Mechanical"
  case superElectronic = "Super Electronic"
  case goldenEagle = "Golden Eagle"
  case digital = "Neo Digital"
  case brightDigital = "Bright Digital"

  var id: String { rawValue }
  var label: String { rawValue }
  var systemImage: String {
    switch self {
    case .superMeter:
      return "gauge.with.dots.needle.67percent"
    case .superElectronic:
      return "digitalcrown.horizontal.arrow.counterclockwise"
    case .goldenEagle:
      return "bird"
    case .digital:
      return "display"
    case .brightDigital:
      return "rectangle.3.offgrid"
    }
  }

  var capabilities: MeterCapabilities {
    switch self {
    case .superMeter:
      return MeterCapabilities(
        category: .mechanical,
        displayFields: [.fare],
        statusIndicators: [.forHire]
      )
    case .superElectronic:
      return MeterCapabilities(
        category: .electronic,
        displayFields: [.fare, .waitTime, .distance],
        statusIndicators: [.forHire, .hired, .stop, .nightMode]
      )
    case .goldenEagle:
      return MeterCapabilities(
        category: .electronic,
        displayFields: [.fare, .waitTime, .distance],
        statusIndicators: [.forHire]
      )
    case .digital:
      return MeterCapabilities(
        category: .electronic,
        displayFields: [.fare],
        statusIndicators: [.forHire]
      )
    case .brightDigital:
      return MeterCapabilities(
        category: .electronic,
        displayFields: [.fare, .waitTime, .distance],
        statusIndicators: [.forHire]
      )
    }
  }
}

// MARK: - Meter Render Mode

enum MeterRenderMode: String, CaseIterable, Identifiable {
  case full = "Full"
  case displayOnly = "Display"

  var id: String { rawValue }
  var label: String { rawValue }
}

// MARK: - Digit Wheel Style

enum DigitWheelStyle: String, CaseIterable, Identifiable {
  case drum = "Drum"
  case disk = "Disk"

  var id: String { rawValue }
  var label: String { rawValue }
}

// MARK: - Shared Meter Dimensions

/// Shared width ratio for all meters - ensures consistent width across meter styles
enum MeterDimensions {
  static let widthRatio: CGFloat = 1.0
}

// MARK: - Super Mechanical Meter Dimensions

/// Dimension ratios for the Super Mechanical meter
enum SuperMeterDimensions {
  static var widthRatio: CGFloat { MeterDimensions.widthRatio }
  static let bodyAspect: CGFloat = 1.0

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    containerWidth * widthRatio * bodyAspect
  }
}

// MARK: - Super Electronic Meter Dimensions

/// Dimension ratios for the Super Electronic meter
enum SuperElectronicDimensions {
  static var widthRatio: CGFloat { MeterDimensions.widthRatio }
  static let bodyAspect: CGFloat = 1.0

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    containerWidth * widthRatio * bodyAspect
  }
}

// MARK: - Golden Eagle Meter Dimensions

/// Dimension ratios for the Golden Eagle meter
enum GoldenEagleDimensions {
  static var widthRatio: CGFloat { MeterDimensions.widthRatio }
  static let bodyAspect: CGFloat = 1.0

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    containerWidth * widthRatio * bodyAspect
  }
}

// MARK: - Bright Digital Meter Dimensions

/// Dimension ratios for the Bright Digital meter
enum BrightDigitalDimensions {
  static var widthRatio: CGFloat { MeterDimensions.widthRatio }
  static let bodyAspect: CGFloat = 1.0

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    containerWidth * widthRatio * bodyAspect
  }
}

// MARK: - Digital Meter Dimensions

/// Dimension ratios for the Neo Digital meter
enum DigitalDimensions {
  static var widthRatio: CGFloat { MeterDimensions.widthRatio }
  static let bodyAspect: CGFloat = 1.0

  static func naturalHeight(for containerWidth: CGFloat) -> CGFloat {
    containerWidth * widthRatio * bodyAspect
  }
}

// MARK: - Meter Shell Style

/// Configuration for meter shell appearance
struct MeterShellStyle {
  let widthRatio: CGFloat
  let bodyAspect: CGFloat
  let cornerRadiusRatio: CGFloat
  let bodyGradientColors: [Color]
  let strokeOpacity: Double
  let strokeLineWidth: CGFloat
  let shadowOpacity: Double
  let shadowRadius: CGFloat
  let shadowYOffset: CGFloat
  let alignment: Alignment
}

extension MeterShellStyle {
  static let superMechanical = MeterShellStyle(
    widthRatio: SuperMeterDimensions.widthRatio,
    bodyAspect: SuperMeterDimensions.bodyAspect,
    cornerRadiusRatio: 0.08,
    bodyGradientColors: MeterColorSchemes.MeterShell.superDark,
    strokeOpacity: 0.08,
    strokeLineWidth: 1.2,
    shadowOpacity: 0.35,
    shadowRadius: 16,
    shadowYOffset: 10,
    alignment: .top
  )

  static let superElectronic = MeterShellStyle(
    widthRatio: SuperElectronicDimensions.widthRatio,
    bodyAspect: SuperElectronicDimensions.bodyAspect,
    cornerRadiusRatio: 0.08,
    bodyGradientColors: MeterColorSchemes.MeterShell.superDark,
    strokeOpacity: 0.08,
    strokeLineWidth: 1.2,
    shadowOpacity: 0.35,
    shadowRadius: 16,
    shadowYOffset: 10,
    alignment: .top
  )

  static let goldenEagle = MeterShellStyle(
    widthRatio: GoldenEagleDimensions.widthRatio,
    bodyAspect: GoldenEagleDimensions.bodyAspect,
    cornerRadiusRatio: 0.08,
    bodyGradientColors: MeterColorSchemes.MeterShell.golden,
    strokeOpacity: 0.4,
    strokeLineWidth: 1.2,
    shadowOpacity: 0.35,
    shadowRadius: 16,
    shadowYOffset: 10,
    alignment: .top
  )

  static let brightDigital = MeterShellStyle(
    widthRatio: BrightDigitalDimensions.widthRatio,
    bodyAspect: BrightDigitalDimensions.bodyAspect,
    cornerRadiusRatio: 0.08,
    bodyGradientColors: MeterColorSchemes.MeterShell.brightDigital,
    strokeOpacity: 0.08,
    strokeLineWidth: 1.2,
    shadowOpacity: 0.4,
    shadowRadius: 16,
    shadowYOffset: 10,
    alignment: .top
  )

  static let digital = MeterShellStyle(
    widthRatio: DigitalDimensions.widthRatio,
    bodyAspect: DigitalDimensions.bodyAspect,
    cornerRadiusRatio: 0.08,
    bodyGradientColors: MeterColorSchemes.MeterShell.digital,
    strokeOpacity: 0.08,
    strokeLineWidth: 1,
    shadowOpacity: 0.4,
    shadowRadius: 14,
    shadowYOffset: 8,
    alignment: .center
  )
}

// MARK: - Meter Shell

/// Container that handles geometry scaling and shell rendering for meter panels
struct MeterShell<Content: View>: View {
  let style: MeterShellStyle
  @Environment(\.colorScheme) private var colorScheme
  @ViewBuilder let content: (_ bodyWidth: CGFloat, _ bodyHeight: CGFloat) -> Content

  init(
    style: MeterShellStyle,
    @ViewBuilder content: @escaping (_ bodyWidth: CGFloat, _ bodyHeight: CGFloat) -> Content
  ) {
    self.style = style
    self.content = content
  }

  var body: some View {
    GeometryReader { geo in
      let desiredWidth = max(geo.size.width * style.widthRatio, 0)
      let bodyHeightForWidth = desiredWidth * style.bodyAspect
      let rawScale = bodyHeightForWidth > 0 ? geo.size.height / bodyHeightForWidth : 0
      let scale = rawScale.isFinite ? min(1, max(rawScale, 0)) : 0
      let bodyWidth = desiredWidth * scale
      let bodyHeight = bodyHeightForWidth * scale
      let cornerRadius = bodyWidth * style.cornerRadiusRatio
      let effectiveStrokeOpacity = colorScheme == .dark
        ? max(style.strokeOpacity, 0.35)
        : style.strokeOpacity

      ZStack {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(
            LinearGradient(
              colors: style.bodyGradientColors,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .stroke(Color.white.opacity(effectiveStrokeOpacity), lineWidth: style.strokeLineWidth)
          )
          .shadow(
            color: .black.opacity(style.shadowOpacity),
            radius: style.shadowRadius,
            x: 0,
            y: style.shadowYOffset
          )

        content(bodyWidth, bodyHeight)
      }
      .frame(width: bodyWidth, height: bodyHeight)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style.alignment)
    }
  }
}

// MARK: - Safe Area Insets Helper

@MainActor
var windowSafeAreaInsets: UIEdgeInsets {
  UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap { $0.windows }
    .first { $0.isKeyWindow }?
    .safeAreaInsets ?? .zero
}

// MARK: - Hire Pulse Animation

struct HirePulseModifier: ViewModifier {
  let tripState: TripMeterState
  let duration: Double
  @Binding var pulse: Bool

  func body(content: Content) -> some View {
    content
      .onAppear {
        if tripState == .forHire {
          startPulse()
        }
      }
      .onChange(of: tripState) { _, newValue in
        if newValue == .forHire {
          startPulse()
        } else {
          pulse = false
        }
      }
  }

  private func startPulse() {
    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
      pulse = true
    }
  }
}

extension View {
  func hirePulse(tripState: TripMeterState, duration: Double = 1.2, pulse: Binding<Bool>) -> some View {
    modifier(HirePulseModifier(tripState: tripState, duration: duration, pulse: pulse))
  }
}

// MARK: - City / Vehicle Label

struct MeterCityVehicleLabel: View {
  let text: String
  let fontSize: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: max(fontSize, 8), weight: .medium, design: .rounded))
      .foregroundStyle(.white.opacity(0.85))
      .lineLimit(1)
      .minimumScaleFactor(0.6)
  }
}
