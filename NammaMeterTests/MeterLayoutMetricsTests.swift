import CoreGraphics
import XCTest
@testable import NammaMeter

final class MeterLayoutMetricsTests: XCTestCase {
  func testMetricsClampWhenContainerIsZero() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 0, height: 0))

    XCTAssertEqual(metrics.availableHeight, 0)
    XCTAssertEqual(metrics.referenceMeterHeight, 0)
    XCTAssertEqual(metrics.fixedMapHeight, 0)
    XCTAssertEqual(metrics.controlBarHeight, 56)
  }

  func testMetricsClampWhenContainerIsTooSmallForMap() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 320, height: 80))

    XCTAssertEqual(metrics.availableHeight, 8)
    XCTAssertEqual(metrics.referenceMeterHeight, 0)
    XCTAssertEqual(metrics.fixedMapHeight, 8)
    XCTAssertEqual(metrics.controlBarHeight, 56)
  }
}
