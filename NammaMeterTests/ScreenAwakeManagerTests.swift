import XCTest
import UIKit
@testable import NammaMeter

@MainActor
final class ScreenAwakeManagerTests: XCTestCase {
  var sut: ScreenAwakeManager!

  override func setUp() async throws {
    try await super.setUp()
    await MainActor.run {
      sut = ScreenAwakeManager()
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }

  override func tearDown() async throws {
    await MainActor.run {
      UIApplication.shared.isIdleTimerDisabled = false
      sut = nil
    }
    try await super.tearDown()
  }

  func testIdleTimerDisabledWhenEnabledAndInProgressAndAppActive() {
    sut.isEnabled = true
    sut.tripState = .inProgress

    XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)
  }

  func testIdleTimerEnabledWhenFeatureDisabled() {
    sut.isEnabled = false
    sut.tripState = .inProgress

    XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
  }

  func testIdleTimerEnabledWhenTripEnds() {
    sut.isEnabled = true
    sut.tripState = .inProgress
    XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)

    sut.tripState = .complete

    XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
  }

  func testIdleTimerEnabledWhenTripNotStarted() {
    sut.isEnabled = true
    sut.tripState = .forHire

    XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
  }

  func testIdleTimerEnabledWhenSettingToggled() {
    sut.isEnabled = true
    sut.tripState = .inProgress
    XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)

    sut.isEnabled = false

    XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
  }

  func testIdleTimerDeinitResetsState() {
    sut.isEnabled = true
    sut.tripState = .inProgress
    XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)

    sut = nil

    // Give async deinit time to complete
    let expectation = XCTestExpectation(description: "Idle timer reset")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1)

    XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
  }
}
