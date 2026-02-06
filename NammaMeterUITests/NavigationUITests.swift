@preconcurrency import XCTest

final class NavigationUITests: NammaMeterUITestCase {

  func testTabSwitching() {
    let meterTab = app.tabBars.buttons["Meter"]
    let tripsTab = app.tabBars.buttons["Trips"]
    let settingsTab = app.tabBars.buttons["Settings"]

    XCTAssertTrue(waitFor(meterTab))

    // Switch to Trips
    tripsTab.tap()
    XCTAssertTrue(app.staticTexts["Trips"].waitForExistence(timeout: 3))

    // Switch to Settings
    settingsTab.tap()
    XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))

    // Switch back to Meter
    meterTab.tap()
    XCTAssertTrue(app.buttons["meter.tripToggle"].waitForExistence(timeout: 3))
  }

  func testMeterSettingsSheet() {
    let settingsButton = app.buttons["meter.settingsButton"]
    XCTAssertTrue(waitFor(settingsButton))

    settingsButton.tap()

    // Verify sheet content
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Meter Style"].exists)
    XCTAssertTrue(app.buttons["Super Mechanical"].exists)
    XCTAssertTrue(app.buttons["Super Electronic"].exists)

    // Dismiss
    doneButton.tap()
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
  }

  func testManageCitiesNavigation() {
    tapTab("Settings")

    let manageCities = app.staticTexts["Manage Cities"]
    XCTAssertTrue(manageCities.waitForExistence(timeout: 5))
    manageCities.tap()

    // Verify navigation pushed
    XCTAssertTrue(app.navigationBars["Manage Cities"].waitForExistence(timeout: 3))

    // Navigate back
    app.navigationBars.buttons.element(boundBy: 0).tap()

    // Verify we're back on Settings
    XCTAssertTrue(manageCities.waitForExistence(timeout: 3))
  }
}
