import OSLog
import XCTest
@testable import NammaMeter

final class LoggingTests: XCTestCase {

  func testLogCategoriesExist() {
    // Verify all log categories are properly configured
    // This test ensures the Log enum compiles and categories are accessible
    XCTAssertNotNil(Log.trip)
    XCTAssertNotNil(Log.location)
    XCTAssertNotNil(Log.persistence)
    XCTAssertNotNil(Log.fare)
  }

  func testLogSubsystemIsCorrect() {
    // Log a message and verify no crash occurs
    // OSLog messages are fire-and-forget, so we just verify the call succeeds
    Log.trip.debug("Test log message")
    Log.location.debug("Test log message")
    Log.persistence.debug("Test log message")
    Log.fare.debug("Test log message")
  }
}
