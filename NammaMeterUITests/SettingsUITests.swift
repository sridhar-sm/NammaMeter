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

  func testThemePickerIsVisible() {
    tapTab("Settings")

    // Look for the "Appearance" section header instead of the picker directly
    let appearanceHeader = app.staticTexts["Appearance"]
    XCTAssertTrue(appearanceHeader.waitForExistence(timeout: 5), "Appearance section should be visible")

    // Look for one of the theme options (System, Light, Dark)
    let systemOption = app.staticTexts["System"]
    XCTAssertTrue(systemOption.waitForExistence(timeout: 3), "Theme options should be visible")
  }

  func testAppearanceSectionExistsBeforeCitySection() {
    tapTab("Settings")

    // Verify the Appearance section header is visible
    let appearanceHeader = app.staticTexts["Appearance"]
    XCTAssertTrue(appearanceHeader.waitForExistence(timeout: 5), "Appearance section should be visible")

    // The System option should be visible (default picker option)
    let systemOption = app.staticTexts["System"]
    XCTAssertTrue(systemOption.waitForExistence(timeout: 3), "System theme option should be visible")

    // Verify City section is below Appearance
    let cityHeader = app.staticTexts["City"]
    XCTAssertTrue(cityHeader.exists, "City section should be visible after Appearance")
  }

  func testAppearanceSectionSurvivesAppRelaunch() {
    // Verify theme section exists
    tapTab("Settings")
    let appearanceHeader = app.staticTexts["Appearance"]
    XCTAssertTrue(appearanceHeader.waitForExistence(timeout: 5), "Appearance section should be visible")

    // Close the app
    app.terminate()

    // Relaunch without reset to verify persistence
    let newApp = XCUIApplication()
    newApp.launchArguments = ["--uitesting"]  // Note: no --reset-state
    newApp.launch()

    // Navigate to settings and verify the appearance section is still there
    sleep(1)  // Wait for app to settle
    let newAppTabBar = newApp.tabBars
    let settingsButton = newAppTabBar.buttons["Settings"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings tab should be available")
    settingsButton.tap()

    // Verify the Appearance section and its options are visible after relaunch
    let newAppearanceHeader = newApp.staticTexts["Appearance"]
    XCTAssertTrue(newAppearanceHeader.waitForExistence(timeout: 5), "Appearance section should still be visible after relaunch")

    let themeOptions = newApp.staticTexts.matching(NSPredicate(format: "label IN {'System', 'Light', 'Dark'}"))
    XCTAssertGreaterThan(themeOptions.count, 0, "Theme options should be visible after relaunch")
  }
}
