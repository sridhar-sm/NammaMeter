@preconcurrency import XCTest

final class SettingsUITests: NammaMeterUITestCase {

  func testDefaultCityDisplayed() {
    tapTab("Settings")
    let bengaluru = app.staticTexts["Bengaluru"]
    XCTAssertTrue(bengaluru.waitForExistence(timeout: 5), "Default city Bengaluru should be visible")
  }

  func testRatesDisplayed() {
    tapTab("Settings")

    let baseFare = app.staticTexts["Base Fare"]
    XCTAssertTrue(baseFare.waitForExistence(timeout: 5), "Base Fare label should be visible")

    let perKm = app.staticTexts["Per Km"]
    XCTAssertTrue(perKm.waitForExistence(timeout: 3), "Per Km label should be visible")

    let minimumFare = app.staticTexts["Minimum Fare"]
    XCTAssertTrue(minimumFare.waitForExistence(timeout: 3), "Minimum Fare label should be visible")
  }

  func testManageCitiesShowsCatalogCities() {
    tapTab("Settings")

    let manageCities = app.staticTexts["Manage Cities"]
    XCTAssertTrue(manageCities.waitForExistence(timeout: 5))
    manageCities.tap()

    let bengaluru = app.staticTexts["Bengaluru"]
    XCTAssertTrue(bengaluru.waitForExistence(timeout: 5), "Bengaluru should be listed in Manage Cities")
  }

  func testKeepScreenAwakeToggleIsVisible() {
    tapTab("Settings")

    // Scroll down to find Display section with Keep Screen Awake toggle
    app.swipeUp()
    app.swipeUp()

    // Look for keep screen awake toggle
    let toggles = app.switches
    var foundToggle = false
    for toggle in toggles.allElementsBoundByAccessibilityElement {
      if let label = toggle.label as? String, label.contains("Keep Screen Awake") {
        foundToggle = true
        break
      }
    }
    XCTAssertTrue(foundToggle, "Keep Screen Awake toggle should be visible")
  }

  func testKeepScreenAwakeToggleCanBeToggled() {
    tapTab("Settings")

    // Scroll down to find the toggle
    app.swipeUp()
    app.swipeUp()

    // Find the toggle by looking for toggles and checking their label
    let toggles = app.switches
    var toggle: XCUIElement?
    for sw in toggles.allElementsBoundByAccessibilityElement {
      if let label = sw.label as? String, label.contains("Keep Screen Awake") {
        toggle = sw
        break
      }
    }

    guard let toggleElement = toggle else {
      XCTFail("Keep Screen Awake toggle should be present")
      return
    }

    // Test that we can tap the toggle without error
    XCTAssertTrue(toggleElement.isHittable, "Toggle should be hittable")
    toggleElement.tap()

    // Verify the toggle still exists after tapping
    XCTAssertTrue(toggleElement.exists, "Toggle should still exist after tapping")
  }
}
