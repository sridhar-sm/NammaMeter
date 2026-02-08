import XCTest
@testable import NammaMeter

final class TestEnvironmentTests: XCTestCase {

  func testIsRunningTestsTrueWhenXCTestConfigurationPresent() {
    XCTAssertTrue(
      TestEnvironment.isRunningTests(
        environment: ["XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"],
        arguments: []
      )
    )
  }

  func testIsRunningTestsTrueWhenUITestingArgumentPresent() {
    XCTAssertTrue(
      TestEnvironment.isRunningTests(
        environment: [:],
        arguments: ["--uitesting"]
      )
    )
  }

  func testIsRunningTestsFalseWithoutSignals() {
    XCTAssertFalse(
      TestEnvironment.isRunningTests(
        environment: [:],
        arguments: []
      )
    )
  }

  func testIsRunningHostedUnitTestsTrueWhenXCTestConfigurationPresentWithoutUITestArg() {
    XCTAssertTrue(
      TestEnvironment.isRunningHostedUnitTests(
        environment: ["XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"],
        arguments: []
      )
    )
  }

  func testIsRunningHostedUnitTestsFalseWhenUITestingArgumentPresent() {
    XCTAssertFalse(
      TestEnvironment.isRunningHostedUnitTests(
        environment: ["XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"],
        arguments: ["--uitesting"]
      )
    )
  }

  func testShouldResetStateTrueWhenResetArgumentPresent() {
    XCTAssertTrue(TestEnvironment.shouldResetState(arguments: ["--reset-state"]))
  }

  func testShouldResetStateFalseWhenResetArgumentAbsent() {
    XCTAssertFalse(TestEnvironment.shouldResetState(arguments: ["--uitesting"]))
  }
}
