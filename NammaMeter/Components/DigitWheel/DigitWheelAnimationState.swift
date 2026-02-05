import SwiftUI

/// Manages animation state for digit wheel transitions.
/// Tracks current/target digits, rotation, and animation progress.
struct DigitWheelAnimationState {
  /// The currently displayed digit (nil until first appearance).
  var currentDigit: Int?

  /// Cumulative wheel rotation for disk style (in degrees).
  var wheelRotation: CGFloat = 0

  /// Animation progress for drum style (0 to 1).
  var rollProgress: CGFloat = 0

  /// Scroll direction for drum style (-1 = up, 1 = down).
  var rollDirection: CGFloat = -1

  // MARK: - Computed Properties

  /// The base digit to display (current or fallback to 0).
  func baseDigit(fallback: Int) -> Int {
    currentDigit ?? fallback
  }

  /// Calculate the drum roll offset based on current progress.
  func drumOffset(step: CGFloat) -> CGFloat {
    rollDirection * step * rollProgress
  }

  // MARK: - State Updates

  /// Initialize the state with a digit value on first appearance.
  mutating func initializeIfNeeded(with digit: Int) {
    if currentDigit == nil {
      currentDigit = digit
    }
  }

  /// Reset animation state when digit style changes.
  mutating func resetForStyleChange() {
    wheelRotation = 0
    rollProgress = 0
  }

  /// Reset animation state after completion.
  mutating func resetAfterAnimation(newDigit: Int) {
    currentDigit = newDigit
    wheelRotation = 0
    rollProgress = 0
  }

  /// Jump to a new digit without animation.
  mutating func jumpToDigit(_ digit: Int) {
    currentDigit = digit
    wheelRotation = 0
    rollProgress = 0
  }

  /// Begin disk style rotation animation.
  mutating func beginDiskAnimation(direction: CGFloat) {
    wheelRotation = 0
  }

  /// Begin drum style scroll animation.
  mutating func beginDrumAnimation(direction: CGFloat) {
    rollDirection = direction
    rollProgress = 0
  }
}
