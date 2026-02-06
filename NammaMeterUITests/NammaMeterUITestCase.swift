@preconcurrency import XCTest

class NammaMeterUITestCase: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--reset-state"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Helpers

  func tapTab(_ name: String) {
    app.tabBars.buttons[name].tap()
  }

  @discardableResult
  func waitFor(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    element.waitForExistence(timeout: timeout)
  }

  func waitForLabel(_ element: XCUIElement, toBe label: String, timeout: TimeInterval = 5) {
    let predicate = NSPredicate(format: "label == %@", label)
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(result, .completed, "Expected label '\(label)' but got '\(element.label)'")
  }
}
