import CoreGraphics
import XCTest
@testable import NammaMeter

final class MeterLayoutMetricsTests: XCTestCase {

  // MARK: - Zero / Small Containers

  func testMetricsClampWhenContainerIsZero() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 0, height: 0))

    XCTAssertEqual(metrics.meterSide, 0)
    XCTAssertEqual(metrics.fixedMapHeight, 0)
    XCTAssertEqual(metrics.controlBarHeight, 56)
  }

  func testMetricsClampWhenContainerIsTooSmall() {
    // Square container stays in portrait path
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 80, height: 80))

    // meterSide = 80 - 24 = 56
    XCTAssertEqual(metrics.meterSide, 56)
    // fixedMapHeight = max(80 - 0 - 56 - 56 - 8 - 8, 0) = 0
    XCTAssertEqual(metrics.fixedMapHeight, 0)
    XCTAssertEqual(metrics.controlBarHeight, 56)
  }

  // MARK: - Landscape Detection

  func testLandscapeDetectedWhenWidthExceedsHeight() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 844, height: 390))
    XCTAssertTrue(metrics.isLandscape)
  }

  func testPortraitDetectedWhenHeightExceedsWidth() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 390, height: 844))
    XCTAssertFalse(metrics.isLandscape)
  }

  func testSquareContainerIsNotLandscape() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 400, height: 400))
    XCTAssertFalse(metrics.isLandscape)
  }

  // MARK: - Portrait Metrics (Square Meter)

  func testPortraitMeterSideIsWidthMinusPadding() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 390, height: 844))

    let expectedSide = 390 - MeterLayoutMetrics.uniformPadding * 2
    XCTAssertEqual(metrics.meterSide, expectedSide)
  }

  func testPortraitFixedMapHeightFillsRemaining() {
    let safeAreaTop: CGFloat = 59
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 390, height: 844), safeAreaTop: safeAreaTop)

    let meterSide = 390 - MeterLayoutMetrics.uniformPadding * 2
    let usedHeight = safeAreaTop + meterSide + 56 + MeterLayoutMetrics.spacing * 2
    let expectedMap = max(844 - usedHeight, 0)
    XCTAssertEqual(metrics.fixedMapHeight, expectedMap, accuracy: 0.01)
    XCTAssertGreaterThan(metrics.fixedMapHeight, 0)
  }

  // MARK: - Landscape Metrics (Square Meter)

  func testLandscapeMeterSideIsHeightMinusPadding() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 844, height: 390))

    let expectedSide = 390 - MeterLayoutMetrics.landscapeTopPadding
    XCTAssertEqual(metrics.meterSide, expectedSide)
  }

  func testLandscapeFixedMapHeightEqualsMeterSide() {
    let metrics = MeterLayoutMetrics(containerSize: CGSize(width: 844, height: 390))
    XCTAssertEqual(metrics.fixedMapHeight, metrics.meterSide)
  }
}
