import Foundation

enum TestEnvironment {
  static var isRunningTests: Bool {
    isRunningTests(
      environment: ProcessInfo.processInfo.environment,
      arguments: ProcessInfo.processInfo.arguments
    )
  }

  static var isRunningHostedUnitTests: Bool {
    isRunningHostedUnitTests(
      environment: ProcessInfo.processInfo.environment,
      arguments: ProcessInfo.processInfo.arguments
    )
  }

  static var shouldResetState: Bool {
    shouldResetState(arguments: ProcessInfo.processInfo.arguments)
  }

  static func isRunningTests(
    environment: [String: String],
    arguments: [String]
  ) -> Bool {
    environment["XCTestConfigurationFilePath"] != nil || arguments.contains("--uitesting")
  }

  static func isRunningHostedUnitTests(
    environment: [String: String],
    arguments: [String]
  ) -> Bool {
    environment["XCTestConfigurationFilePath"] != nil && !arguments.contains("--uitesting")
  }

  static func shouldResetState(arguments: [String]) -> Bool {
    arguments.contains("--reset-state")
  }
}
