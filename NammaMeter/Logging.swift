import OSLog

/// Structured logging categories for the app.
///
/// Usage:
/// ```swift
/// Log.trip.info("Trip started")
/// Log.location.debug("Location update: \(coordinate, privacy: .private)")
/// ```
enum Log {
  private static let subsystem = "sridharsm.NammaMeter"

  /// Trip lifecycle events (start, stop, reset, fare updates)
  static let trip = Logger(subsystem: subsystem, category: "trip")

  /// Location updates and permission changes
  static let location = Logger(subsystem: subsystem, category: "location")

  /// Persistence operations (save, load, errors)
  static let persistence = Logger(subsystem: subsystem, category: "persistence")

  /// Fare calculations and rate changes
  static let fare = Logger(subsystem: subsystem, category: "fare")
}
