import Foundation
import XCTest
@testable import NammaMeter

struct TestHelpers {
  static func makeTempURL(filename: String) throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent(filename)
  }

  static func makeTrip(fare: Double, name: String? = nil) -> Trip {
    Trip(
      id: UUID(),
      startDate: Date(timeIntervalSince1970: 1000000),
      endDate: Date(timeIntervalSince1970: 1001800),
      distanceMeters: 5000,
      duration: 1800,
      fare: fare,
      points: [],
      conditions: .clear,
      rateSnapshot: RateSnapshot(settings: .bengaluruDefault),
      multiplier: 1.0,
      name: name
    )
  }

  static func write(settings: FareProfileSettings, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(settings)
    try data.write(to: url, options: [.atomic])
  }

  @MainActor
  static func waitForProfiles(
    _ store: SettingsStore,
    file: StaticString = #filePath,
    line: UInt = #line
  ) async {
    for _ in 0..<60 {
      if !store.profiles.isEmpty {
        return
      }
      try? await Task.sleep(for: .milliseconds(50))
    }
    XCTFail("Timed out waiting for SettingsStore to load", file: file, line: line)
  }

  static func waitForTripStoreLoad(
    _ store: TripStore,
    file: StaticString = #file,
    line: UInt = #line
  ) async {
    for _ in 0..<60 {
      try? await Task.sleep(for: .milliseconds(50))
    }
    try? await Task.sleep(for: .milliseconds(100))
  }
}
