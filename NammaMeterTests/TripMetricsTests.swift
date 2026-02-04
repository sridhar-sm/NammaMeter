import XCTest
@testable import NammaMeter

final class TripMetricsTests: XCTestCase {
  private var metrics: TripMetrics!

  override func setUp() {
    super.setUp()
    metrics = TripMetrics()
  }

  func testMetricsAccumulation() {
    metrics.addDistance(1000)
    metrics.addElapsedTime(300)

    XCTAssertEqual(metrics.distanceMeters, 1000)
    XCTAssertEqual(metrics.elapsedSeconds, 300)
  }

  func testWaitingAccumulation() {
    metrics.addWaitingTime(120)

    XCTAssertEqual(metrics.waitingSeconds, 120)
  }

  func testFormattedOutput() {
    metrics.addDistance(5000)
    XCTAssertEqual(metrics.formattedDistance, "5.00 km")

    metrics.setElapsedTime(3661)
    XCTAssertEqual(metrics.formattedElapsed, "01:01:01")
  }
}
