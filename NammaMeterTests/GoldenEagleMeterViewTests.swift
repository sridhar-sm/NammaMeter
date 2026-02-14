import XCTest
@testable import NammaMeter

final class GoldenEagleMeterViewTests: XCTestCase {
  func testForHireFareDisplayShowsForInMiddleSegments() {
    XCTAssertEqual(
      GoldenEagleForHireFareDisplay.forHireValues,
      [.blank, .character("F"), .character("o"), .character("r"), .blank]
    )
  }

  func testForHireDistanceDisplayShowsHire() {
    XCTAssertEqual(
      GoldenEagleHireDistanceDisplay.forHireValues,
      [.character("H"), .character("I"), .character("r"), .character("E")]
    )
  }
}
