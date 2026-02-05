import SwiftUI

/// A reusable mechanical digit wheel component that supports both disk and drum animation styles.
/// Extracts rendering and animation logic from the meter display for reusability and testability.
struct MechanicalDigitWheel: View {
  let digit: String
  let isAccent: Bool
  let digitStyle: DigitWheelStyle

  @State private var animationState = DigitWheelAnimationState()

  private var renderer: DigitWheelRenderer {
    DigitWheelRenderer(digitStyle: digitStyle)
  }

  var body: some View {
    GeometryReader { geo in
      let height = geo.size.height
      let fontSize = renderer.fontSize(cellHeight: height)
      let baseDigit = animationState.baseDigit(fallback: Int(digit) ?? 0)
      let prevDigit = renderer.previousDigit(from: baseDigit)
      let nextDigit = renderer.nextDigit(from: baseDigit)
      let (windowWidth, windowHeight) = renderer.windowDimensions(
        cellWidth: geo.size.width, cellHeight: height)
      let windowShape = Capsule()
      let wheelFill = wheelGradient(windowWidth: windowWidth, windowHeight: windowHeight)
      let wheelDiameter = renderer.wheelDiameter(windowWidth: windowWidth, windowHeight: windowHeight)
      let stepAngle = DigitWheelRenderer.rotationPerDigit
      let radius = renderer.diskRadius(windowHeight: windowHeight)
      let step = renderer.drumStep(height: height)
      let rollOffset = animationState.drumOffset(step: step)
      let verticalBias = renderer.diskVerticalBias(windowHeight: windowHeight)

      ZStack {
        // Window background
        windowShape
          .fill(Color.black.opacity(0.78))
          .frame(width: windowWidth, height: windowHeight)
          .overlay(
            windowShape
              .stroke(Color.black.opacity(0.85), lineWidth: 1)
              .frame(width: windowWidth, height: windowHeight)
          )
          .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 2)

        // Wheel and digits
        ZStack {
          Circle()
            .fill(wheelFill)
            .frame(width: wheelDiameter, height: wheelDiameter)
            .overlay(
              Circle()
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
            )

          ZStack {
            if digitStyle == .disk {
              diskDigit(
                String(prevDigit),
                angle: -stepAngle + animationState.wheelRotation,
                radius: radius,
                fontSize: renderer.secondaryFontSize(cellHeight: height),
                opacity: 0.35
              )

              diskDigit(
                String(baseDigit),
                angle: animationState.wheelRotation,
                radius: radius,
                fontSize: fontSize,
                opacity: 1
              )

              diskDigit(
                String(nextDigit),
                angle: stepAngle + animationState.wheelRotation,
                radius: radius,
                fontSize: renderer.secondaryFontSize(cellHeight: height),
                opacity: 0.35
              )
            } else {
              drumDigit(
                String(prevDigit),
                offset: -step,
                fontSize: renderer.secondaryFontSize(cellHeight: height),
                opacity: 0.35
              )
              drumDigit(
                String(baseDigit),
                offset: 0,
                fontSize: fontSize,
                opacity: 1
              )
              drumDigit(
                String(nextDigit),
                offset: step,
                fontSize: renderer.secondaryFontSize(cellHeight: height),
                opacity: 0.35
              )
            }
          }
          .offset(y: (digitStyle == .drum ? rollOffset : 0) + (digitStyle == .disk ? verticalBias : 0))
          .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .mask(
          windowShape
            .frame(width: windowWidth, height: windowHeight)
            .padding(2)
        )
        .overlay(
          LinearGradient(
            colors: [Color.white.opacity(0.28), Color.clear, Color.black.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
          )
          .mask(
            windowShape
              .frame(width: windowWidth, height: windowHeight)
              .padding(2)
          )
        )
      }
      .overlay(
        windowShape
          .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
          .frame(width: windowWidth, height: windowHeight)
          .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
      )
    }
    .onAppear {
      animationState.initializeIfNeeded(with: Int(digit) ?? 0)
    }
    .onChange(of: digitStyle) { _, _ in
      animationState.resetForStyleChange()
    }
    .onChange(of: digit) { _, newValue in
      handleDigitChange(to: newValue)
    }
  }

  // MARK: - Wheel Gradient

  private func wheelGradient(windowWidth: CGFloat, windowHeight: CGFloat) -> AnyShapeStyle {
    if digitStyle == .disk {
      return AnyShapeStyle(
        RadialGradient(
          colors: [
            Color.white,
            MeterColorSchemes.SuperMechanical.highlightPanel[0],
            MeterColorSchemes.SuperMechanical.highlightPanel[1],
            MeterColorSchemes.SuperMechanical.highlightPanel[2],
          ],
          center: .center,
          startRadius: 2,
          endRadius: max(windowWidth, windowHeight) * 0.9
        )
      )
    } else {
      return AnyShapeStyle(
        LinearGradient(
          colors: [
            Color.white,
            MeterColorSchemes.SuperMechanical.highlightPanelAlt[0],
            MeterColorSchemes.SuperMechanical.highlightPanelAlt[1],
            MeterColorSchemes.SuperMechanical.highlightPanelAlt[2],
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    }
  }

  // MARK: - Digit Change Handling

  private func handleDigitChange(to newValue: String) {
    guard let newDigit = Int(newValue) else { return }
    guard let oldDigit = animationState.currentDigit else {
      animationState.currentDigit = newDigit
      return
    }
    if newDigit == oldDigit { return }

    if let direction = renderer.animationDirection(from: oldDigit, to: newDigit) {
      animateRoll(to: newDigit, direction: direction)
    } else {
      animationState.jumpToDigit(newDigit)
    }
  }

  private func animateRoll(to newDigit: Int, direction: CGFloat) {
    let animationDuration = renderer.animationDuration
    let totalDuration = renderer.totalAnimationDuration

    if digitStyle == .disk {
      animationState.beginDiskAnimation(direction: direction)
      withAnimation(.easeInOut(duration: animationDuration)) {
        animationState.wheelRotation = renderer.rotationAmount(direction: direction)
      }
    } else {
      animationState.beginDrumAnimation(direction: direction)
      withAnimation(.easeInOut(duration: animationDuration)) {
        animationState.rollProgress = 1
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
      animationState.resetAfterAnimation(newDigit: newDigit)
    }
  }

  // MARK: - Digit Rendering

  private func digitFont(for value: String, size: CGFloat) -> Font {
    if value == "0" {
      return .system(size: size, weight: .bold, design: .rounded)
    }
    return .system(size: size, weight: .bold, design: .monospaced)
  }

  private func digitColor(isAccent: Bool) -> Color {
    isAccent
      ? MeterColorSchemes.SuperMechanical.accentDigit : MeterColorSchemes.SuperMechanical.digitInk
  }

  private func diskDigit(
    _ value: String, angle: CGFloat, radius: CGFloat, fontSize: CGFloat, opacity: CGFloat
  ) -> some View {
    Text(value)
      .font(digitFont(for: value, size: fontSize))
      .foregroundStyle(digitColor(isAccent: isAccent).opacity(opacity))
      .scaleEffect(x: 0.94, y: 1.08)
      .rotationEffect(.degrees(-angle))
      .offset(y: -radius)
      .rotationEffect(.degrees(angle))
  }

  private func drumDigit(_ value: String, offset: CGFloat, fontSize: CGFloat, opacity: CGFloat)
    -> some View
  {
    Text(value)
      .font(digitFont(for: value, size: fontSize))
      .foregroundStyle(digitColor(isAccent: isAccent).opacity(opacity))
      .scaleEffect(x: 0.94, y: 1.08)
      .offset(y: offset)
  }
}
