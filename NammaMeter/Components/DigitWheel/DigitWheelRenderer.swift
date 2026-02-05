import SwiftUI

/// Pure calculation logic for digit wheel rendering.
/// Handles rotation math, positioning, and animation parameters.
struct DigitWheelRenderer {
  let digitStyle: DigitWheelStyle

  // MARK: - Animation Constants

  /// Degrees of rotation per digit (360° / 10 digits)
  static let rotationPerDigit: CGFloat = 36.0

  /// Animation duration for disk style
  static let diskAnimationDuration: Double = 0.24

  /// Animation duration for drum style
  static let drumAnimationDuration: Double = 0.22

  /// Additional delay after animation before state reset
  static let completionDelay: Double = 0.02

  // MARK: - Animation Duration

  var animationDuration: Double {
    digitStyle == .disk ? Self.diskAnimationDuration : Self.drumAnimationDuration
  }

  var totalAnimationDuration: Double {
    animationDuration + Self.completionDelay
  }

  // MARK: - Rotation Calculations

  /// Calculate the number of steps forward from old digit to new digit.
  /// Returns a value from 0-9 representing forward steps.
  func forwardSteps(from oldDigit: Int, to newDigit: Int) -> Int {
    (newDigit - oldDigit + 10) % 10
  }

  /// Determine if this digit change should animate (single step) or jump.
  /// Returns the animation direction, or nil if should jump without animation.
  /// - For disk: positive direction = clockwise rotation when increasing
  /// - For drum: negative direction = scroll up when increasing
  func animationDirection(from oldDigit: Int, to newDigit: Int) -> CGFloat? {
    let forward = forwardSteps(from: oldDigit, to: newDigit)
    let baseDirection: CGFloat = digitStyle == .disk ? 1 : -1

    if forward == 1 {
      return baseDirection
    } else if forward == 9 {
      return -baseDirection
    } else {
      return nil  // Jump without animation
    }
  }

  /// Calculate the rotation amount for a single step animation.
  func rotationAmount(direction: CGFloat) -> CGFloat {
    direction * Self.rotationPerDigit
  }

  // MARK: - Digit Stepping

  /// Get the adjacent digit by stepping forward or backward.
  func steppedDigit(from value: Int, by step: Int) -> Int {
    (value + step + 10) % 10
  }

  /// Get the previous digit (one step backward).
  func previousDigit(from value: Int) -> Int {
    steppedDigit(from: value, by: -1)
  }

  /// Get the next digit (one step forward).
  func nextDigit(from value: Int) -> Int {
    steppedDigit(from: value, by: 1)
  }

  // MARK: - Dimension Calculations

  /// Calculate the wheel diameter relative to window dimensions.
  func wheelDiameter(windowWidth: CGFloat, windowHeight: CGFloat) -> CGFloat {
    max(windowWidth, windowHeight) * 1.45
  }

  /// Calculate radius for disk digit positioning.
  func diskRadius(windowHeight: CGFloat) -> CGFloat {
    windowHeight * 0.38
  }

  /// Calculate vertical step for drum digit spacing.
  func drumStep(height: CGFloat) -> CGFloat {
    height * 0.32
  }

  /// Calculate vertical bias for disk style positioning.
  func diskVerticalBias(windowHeight: CGFloat) -> CGFloat {
    windowHeight * 0.35
  }

  /// Calculate window dimensions relative to cell geometry.
  func windowDimensions(cellWidth: CGFloat, cellHeight: CGFloat) -> (width: CGFloat, height: CGFloat) {
    let width = cellWidth * 0.7
    let height = cellHeight * 0.78
    return (width, height)
  }

  /// Calculate font size relative to cell height.
  func fontSize(cellHeight: CGFloat) -> CGFloat {
    min(cellHeight * 0.75, 28)
  }

  /// Calculate secondary font size for adjacent digits.
  func secondaryFontSize(cellHeight: CGFloat) -> CGFloat {
    fontSize(cellHeight: cellHeight) * 0.85
  }
}
