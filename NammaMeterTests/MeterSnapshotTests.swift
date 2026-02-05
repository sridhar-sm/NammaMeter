import SwiftUI
import XCTest
@testable import NammaMeter

@MainActor
final class MeterSnapshotTests: XCTestCase {
  private let snapshotSize = CGSize(width: 390, height: 500)

  override func setUp() {
    super.setUp()
    // Set to true to record new snapshots, false to verify against existing
    // isRecording = true
  }

  // MARK: - Super Mechanical Meter

  func testSuperMechanicalForHire() {
    let view = SuperFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      digitStyle: .disk,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperMechanicalInProgress() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      digitStyle: .disk,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperMechanicalComplete() {
    let view = SuperFullMeterPanel(
      tripState: .complete,
      fare: 256.00,
      digitStyle: .disk,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperMechanicalDrumStyle() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 88.00,
      digitStyle: .drum,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  // MARK: - Super Electronic Meter

  func testSuperElectronicForHire() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0,
      isNight: false,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperElectronicInProgress() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      waitingDuration: 300, // 5 minutes
      distanceMeters: 3500,
      isNight: false,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperElectronicNightMode() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 189.00,
      waitingDuration: 600,
      distanceMeters: 5000,
      isNight: true,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  // MARK: - Golden Eagle Meter

  func testGoldenEagleForHire() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0,
      isNight: false,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testGoldenEagleInProgress() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .inProgress,
      fare: 156.00,
      waitingDuration: 420,
      distanceMeters: 4200,
      isNight: false,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  // MARK: - Digital Meter

  func testDigitalForHire() {
    let view = DigitalFullMeterPanel(
      tripState: .forHire,
      fare: 0
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testDigitalInProgress() {
    let view = DigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 78.50
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  // MARK: - Bright Digital Meter

  func testBrightDigitalForHire() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testBrightDigitalInProgress() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 112.00,
      waitingDuration: 180,
      distanceMeters: 2800,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  // MARK: - Edge Cases

  func testSuperMechanicalMaxFare() {
    let view = SuperFullMeterPanel(
      tripState: .complete,
      fare: 9999.99,
      digitStyle: .disk,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }

  func testSuperElectronicLongTrip() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 850.00,
      waitingDuration: 3600, // 1 hour
      distanceMeters: 25000, // 25 km
      isNight: false,
      topInset: 60
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize)
  }
}
