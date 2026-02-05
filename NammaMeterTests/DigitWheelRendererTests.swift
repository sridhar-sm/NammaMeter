import XCTest

@testable import NammaMeter

final class DigitWheelRendererTests: XCTestCase {
  private var diskRenderer: DigitWheelRenderer!
  private var drumRenderer: DigitWheelRenderer!

  override func setUp() {
    super.setUp()
    diskRenderer = DigitWheelRenderer(digitStyle: .disk)
    drumRenderer = DigitWheelRenderer(digitStyle: .drum)
  }

  // MARK: - Forward Steps Calculation

  func testForwardStepsSimple() {
    XCTAssertEqual(diskRenderer.forwardSteps(from: 5, to: 8), 3)
    XCTAssertEqual(diskRenderer.forwardSteps(from: 0, to: 3), 3)
  }

  func testForwardStepsWrapAround() {
    // 9 -> 0 is 1 step forward
    XCTAssertEqual(diskRenderer.forwardSteps(from: 9, to: 0), 1)
    // 8 -> 1 is 3 steps forward (8->9->0->1)
    XCTAssertEqual(diskRenderer.forwardSteps(from: 8, to: 1), 3)
  }

  func testForwardStepsBackward() {
    // Going "backward" from 5 to 3 is actually 8 steps forward (5->6->7->8->9->0->1->2->3)
    XCTAssertEqual(diskRenderer.forwardSteps(from: 5, to: 3), 8)
    // 0 -> 9 is 9 steps forward
    XCTAssertEqual(diskRenderer.forwardSteps(from: 0, to: 9), 9)
  }

  func testForwardStepsSameDigit() {
    XCTAssertEqual(diskRenderer.forwardSteps(from: 5, to: 5), 0)
  }

  // MARK: - Animation Direction

  func testAnimationDirectionSingleStepForward() {
    // Disk: forward 1 step = positive direction (clockwise)
    XCTAssertEqual(diskRenderer.animationDirection(from: 5, to: 6), 1)
    XCTAssertEqual(diskRenderer.animationDirection(from: 9, to: 0), 1)

    // Drum: forward 1 step = negative direction (scroll up)
    XCTAssertEqual(drumRenderer.animationDirection(from: 5, to: 6), -1)
    XCTAssertEqual(drumRenderer.animationDirection(from: 9, to: 0), -1)
  }

  func testAnimationDirectionSingleStepBackward() {
    // Disk: backward 1 step (forward 9) = negative direction
    XCTAssertEqual(diskRenderer.animationDirection(from: 6, to: 5), -1)
    XCTAssertEqual(diskRenderer.animationDirection(from: 0, to: 9), -1)

    // Drum: backward 1 step = positive direction (scroll down)
    XCTAssertEqual(drumRenderer.animationDirection(from: 6, to: 5), 1)
    XCTAssertEqual(drumRenderer.animationDirection(from: 0, to: 9), 1)
  }

  func testAnimationDirectionJump() {
    // More than 1 step = jump (nil direction)
    XCTAssertNil(diskRenderer.animationDirection(from: 5, to: 8))
    XCTAssertNil(diskRenderer.animationDirection(from: 0, to: 5))
    XCTAssertNil(drumRenderer.animationDirection(from: 5, to: 8))
  }

  func testAnimationDirectionSameDigit() {
    // Same digit = no animation needed
    XCTAssertNil(diskRenderer.animationDirection(from: 5, to: 5))
  }

  // MARK: - Rotation Amount

  func testRotationAmount() {
    XCTAssertEqual(diskRenderer.rotationAmount(direction: 1), 36)
    XCTAssertEqual(diskRenderer.rotationAmount(direction: -1), -36)
  }

  // MARK: - Digit Stepping

  func testSteppedDigitForward() {
    XCTAssertEqual(diskRenderer.steppedDigit(from: 5, by: 1), 6)
    XCTAssertEqual(diskRenderer.steppedDigit(from: 9, by: 1), 0)
  }

  func testSteppedDigitBackward() {
    XCTAssertEqual(diskRenderer.steppedDigit(from: 5, by: -1), 4)
    XCTAssertEqual(diskRenderer.steppedDigit(from: 0, by: -1), 9)
  }

  func testPreviousDigit() {
    XCTAssertEqual(diskRenderer.previousDigit(from: 5), 4)
    XCTAssertEqual(diskRenderer.previousDigit(from: 0), 9)
  }

  func testNextDigit() {
    XCTAssertEqual(diskRenderer.nextDigit(from: 5), 6)
    XCTAssertEqual(diskRenderer.nextDigit(from: 9), 0)
  }

  // MARK: - Animation Duration

  func testAnimationDurationDisk() {
    XCTAssertEqual(diskRenderer.animationDuration, 0.24)
  }

  func testAnimationDurationDrum() {
    XCTAssertEqual(drumRenderer.animationDuration, 0.22)
  }

  func testTotalAnimationDuration() {
    XCTAssertEqual(diskRenderer.totalAnimationDuration, 0.26)
    XCTAssertEqual(drumRenderer.totalAnimationDuration, 0.24)
  }

  // MARK: - Dimension Calculations

  func testWheelDiameter() {
    let diameter = diskRenderer.wheelDiameter(windowWidth: 50, windowHeight: 80)
    XCTAssertEqual(diameter, 80 * 1.45)
  }

  func testDiskRadius() {
    let radius = diskRenderer.diskRadius(windowHeight: 100)
    XCTAssertEqual(radius, 38)
  }

  func testDrumStep() {
    let step = drumRenderer.drumStep(height: 100)
    XCTAssertEqual(step, 32)
  }

  func testDiskVerticalBias() {
    let bias = diskRenderer.diskVerticalBias(windowHeight: 100)
    XCTAssertEqual(bias, 35)
  }

  func testWindowDimensions() {
    let (width, height) = diskRenderer.windowDimensions(cellWidth: 100, cellHeight: 100)
    XCTAssertEqual(width, 70)
    XCTAssertEqual(height, 78)
  }

  func testFontSize() {
    // min(height * 0.75, 28)
    XCTAssertEqual(diskRenderer.fontSize(cellHeight: 30), 22.5)
    XCTAssertEqual(diskRenderer.fontSize(cellHeight: 50), 28)  // Capped at 28
  }

  func testSecondaryFontSize() {
    XCTAssertEqual(diskRenderer.secondaryFontSize(cellHeight: 30), 22.5 * 0.85)
  }

  // MARK: - Constants

  func testRotationPerDigit() {
    XCTAssertEqual(DigitWheelRenderer.rotationPerDigit, 36.0)
  }

  func testCompletionDelay() {
    XCTAssertEqual(DigitWheelRenderer.completionDelay, 0.02)
  }
}

// MARK: - Animation State Tests

final class DigitWheelAnimationStateTests: XCTestCase {

  func testInitializeIfNeeded() {
    var state = DigitWheelAnimationState()
    XCTAssertNil(state.currentDigit)

    state.initializeIfNeeded(with: 5)
    XCTAssertEqual(state.currentDigit, 5)

    // Should not overwrite
    state.initializeIfNeeded(with: 8)
    XCTAssertEqual(state.currentDigit, 5)
  }

  func testBaseDigitWithFallback() {
    var state = DigitWheelAnimationState()
    XCTAssertEqual(state.baseDigit(fallback: 3), 3)

    state.currentDigit = 7
    XCTAssertEqual(state.baseDigit(fallback: 3), 7)
  }

  func testDrumOffset() {
    var state = DigitWheelAnimationState()
    state.rollDirection = -1
    state.rollProgress = 0.5

    XCTAssertEqual(state.drumOffset(step: 32), -16)
  }

  func testResetForStyleChange() {
    var state = DigitWheelAnimationState()
    state.wheelRotation = 36
    state.rollProgress = 1

    state.resetForStyleChange()
    XCTAssertEqual(state.wheelRotation, 0)
    XCTAssertEqual(state.rollProgress, 0)
  }

  func testResetAfterAnimation() {
    var state = DigitWheelAnimationState()
    state.currentDigit = 5
    state.wheelRotation = 36
    state.rollProgress = 1

    state.resetAfterAnimation(newDigit: 6)
    XCTAssertEqual(state.currentDigit, 6)
    XCTAssertEqual(state.wheelRotation, 0)
    XCTAssertEqual(state.rollProgress, 0)
  }

  func testJumpToDigit() {
    var state = DigitWheelAnimationState()
    state.wheelRotation = 36
    state.rollProgress = 0.5

    state.jumpToDigit(8)
    XCTAssertEqual(state.currentDigit, 8)
    XCTAssertEqual(state.wheelRotation, 0)
    XCTAssertEqual(state.rollProgress, 0)
  }

  func testBeginDiskAnimation() {
    var state = DigitWheelAnimationState()
    state.wheelRotation = 36

    state.beginDiskAnimation(direction: 1)
    XCTAssertEqual(state.wheelRotation, 0)
  }

  func testBeginDrumAnimation() {
    var state = DigitWheelAnimationState()

    state.beginDrumAnimation(direction: -1)
    XCTAssertEqual(state.rollDirection, -1)
    XCTAssertEqual(state.rollProgress, 0)
  }
}
