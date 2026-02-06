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
}
