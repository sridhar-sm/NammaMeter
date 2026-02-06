@preconcurrency import XCTest

final class HistoryUITests: NammaMeterUITestCase {

  /// Creates a trip by running start/stop/reset from the Meter tab.
  private func createTrip() {
    tapTab("Meter")
    let tripToggle = app.buttons["meter.tripToggle"]
    XCTAssertTrue(tripToggle.waitForExistence(timeout: 3))

    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Stop trip")

    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Reset trip")

    tripToggle.tap()
    waitForLabel(tripToggle, toBe: "Start trip")
  }

  func testEmptyState() {
    tapTab("Trips")
    let emptyState = app.staticTexts["No trips yet"]
    XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
  }

  func testTripAppearsAfterCreation() {
    createTrip()
    tapTab("Trips")

    let emptyState = app.staticTexts["No trips yet"]
    XCTAssertFalse(emptyState.waitForExistence(timeout: 2))

    let cells = app.cells
    XCTAssertGreaterThan(cells.count, 0, "At least one trip row should be visible")
  }

  func testSwipeToDelete() {
    createTrip()
    tapTab("Trips")

    let firstCell = app.cells.element(boundBy: 0)
    XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

    firstCell.swipeLeft()

    let deleteButton = app.buttons["Delete"]
    if deleteButton.waitForExistence(timeout: 2) {
      deleteButton.tap()
    }

    let emptyState = app.staticTexts["No trips yet"]
    XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
  }

  func testBulkDelete() {
    createTrip()
    createTrip()
    tapTab("Trips")

    // Enter edit mode
    let editButton = app.buttons["history.editButton"]
    XCTAssertTrue(editButton.waitForExistence(timeout: 5))
    editButton.tap()

    // Select All
    let selectAll = app.buttons["history.selectAllButton"]
    XCTAssertTrue(selectAll.waitForExistence(timeout: 3))
    selectAll.tap()

    // Delete
    let deleteButton = app.buttons["history.deleteButton"]
    XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
    deleteButton.tap()

    // Verify empty
    let emptyState = app.staticTexts["No trips yet"]
    XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
  }
}
