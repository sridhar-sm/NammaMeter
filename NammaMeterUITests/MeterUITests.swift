@preconcurrency import XCTest

final class MeterUITests: NammaMeterUITestCase {

  func testTripLifecycle() {
    let tripToggle = app.buttons["meter.tripToggle"]
    XCTAssertTrue(waitFor(tripToggle))
    XCTAssertEqual(tripToggle.label, "Start trip")

    // Start trip
    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Stop trip")

    // Stop trip
    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Reset trip")

    // Verify trip saved in History
    tapTab("Trips")
    let emptyState = app.staticTexts["No trips yet"]
    XCTAssertFalse(emptyState.waitForExistence(timeout: 2), "Trip should have been saved to history")

    // Go back and reset
    tapTab("Meter")
    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Start trip")
  }

  func testWaitingToggle() {
    let tripToggle = app.buttons["meter.tripToggle"]
    XCTAssertTrue(waitFor(tripToggle))

    // Start trip
    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Stop trip")

    // Toggle waiting on
    let waitToggle = app.buttons["meter.waitToggle"]
    let enabledPredicate = NSPredicate(format: "isEnabled == true")
    let enabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: waitToggle)
    let enabledResult = XCTWaiter.wait(for: [enabledExpectation], timeout: 5)
    XCTAssertEqual(enabledResult, .completed, "Wait toggle should become enabled")
    waitToggle.tap()
    waitForLabel(waitToggle, toBe: "Resume trip")

    // Toggle waiting off
    waitToggle.tap()
    waitForLabel(waitToggle, toBe: "Pause trip")

    // Clean up
    tripToggle.tap()
  }
}
