import Foundation

enum TestEnvironment {
  static var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }

  static var shouldResetState: Bool {
    ProcessInfo.processInfo.arguments.contains("--reset-state")
  }
}
