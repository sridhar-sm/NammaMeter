import SwiftUI
import XCTest
@testable import NammaMeter

@MainActor
final class MeterSnapshotTests: XCTestCase {
  private let snapshotSize = CGSize(width: 390, height: 500)
  private var isRecordingSnapshots: Bool {
    ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
  }

  override func setUp() {
    super.setUp()
    // To record new snapshots, pass record: true to assertSwiftUIViewSnapshot calls
  }

  // MARK: - Super Mechanical Meter (Light Mode)

  func testSuperMechanicalForHire() {
    let view = SuperFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      digitStyle: .disk
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperMechanicalInProgress() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      digitStyle: .disk
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperMechanicalComplete() {
    let view = SuperFullMeterPanel(
      tripState: .complete,
      fare: 256.00,
      digitStyle: .disk
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperMechanicalDrumStyle() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 88.00,
      digitStyle: .drum
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  // MARK: - Super Electronic Meter (Light Mode)

  func testSuperElectronicForHire() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0,
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperElectronicInProgress() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      waitingDuration: 300, // 5 minutes
      distanceMeters: 3500,
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperElectronicNightMode() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 189.00,
      waitingDuration: 600,
      distanceMeters: 5000,
      isNight: true
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  // MARK: - Golden Eagle Meter (Light Mode)

  func testGoldenEagleForHire() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0,
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testGoldenEagleInProgress() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .inProgress,
      fare: 156.00,
      waitingDuration: 420,
      distanceMeters: 4200,
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  // MARK: - Digital Meter (Light Mode)

  func testDigitalForHire() {
    let view = DigitalFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      fixedNow: Date(timeIntervalSince1970: 1_738_800_000)
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(
      view,
      size: snapshotSize,
      colorScheme: .light,
      record: isRecordingSnapshots
    )
  }

  func testDigitalInProgress() {
    let view = DigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 78.50,
      waitingDuration: 210,
      distanceMeters: 3100,
      elapsed: 840,
      currentSpeedKph: 24.5,
      isNight: true,
      fixedNow: Date(timeIntervalSince1970: 1_738_800_000)
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(
      view,
      size: snapshotSize,
      colorScheme: .light,
      record: isRecordingSnapshots
    )
  }

  func testDigitalWaitingShowsRulesInBottomBar() {
    let view = DigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 78.50,
      waitingDuration: 210,
      distanceMeters: 3100,
      elapsed: 840,
      currentSpeedKph: 0,
      isNight: false,
      isWaiting: true,
      currentRoadName: "M.G. Road",
      fixedNow: Date(timeIntervalSince1970: 1_738_800_000)
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(
      view,
      size: snapshotSize,
      colorScheme: .light,
      record: isRecordingSnapshots
    )
  }

  func testDigitalComplete() {
    let view = DigitalFullMeterPanel(
      tripState: .complete,
      fare: 156.00,
      waitingDuration: 300,
      distanceMeters: 5200,
      elapsed: 1080,
      currentSpeedKph: 0,
      isNight: false,
      fixedNow: Date(timeIntervalSince1970: 1_738_800_000)
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(
      view,
      size: snapshotSize,
      colorScheme: .light,
      record: isRecordingSnapshots
    )
  }

  func testDigitalCompleteDarkMode() {
    let view = DigitalFullMeterPanel(
      tripState: .complete,
      fare: 156.00,
      waitingDuration: 300,
      distanceMeters: 5200,
      elapsed: 1080,
      currentSpeedKph: 0,
      isNight: false,
      fixedNow: Date(timeIntervalSince1970: 1_738_800_000)
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(
      view,
      size: snapshotSize,
      colorScheme: .dark,
      record: isRecordingSnapshots
    )
  }

  // MARK: - Bright Digital Meter (Light Mode)

  func testBrightDigitalForHire() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .forHire,
      fare: 0,
      waitingDuration: 0,
      distanceMeters: 0
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testBrightDigitalInProgress() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 112.00,
      waitingDuration: 180,
      distanceMeters: 2800
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  // MARK: - Edge Cases (Light Mode)

  func testSuperMechanicalMaxFare() {
    let view = SuperFullMeterPanel(
      tripState: .complete,
      fare: 9999.99,
      digitStyle: .disk
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperElectronicLongTrip() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 850.00,
      waitingDuration: 3600, // 1 hour
      distanceMeters: 25000, // 25 km
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  // MARK: - Dark Mode Validation

  func testGoldenEagleDarkMode() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .inProgress,
      fare: 156.00,
      waitingDuration: 420,
      distanceMeters: 4200,
      isNight: false
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .dark, record: isRecordingSnapshots)
  }

  func testBrightDigitalDarkMode() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 112.00,
      waitingDuration: 180,
      distanceMeters: 2800
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .dark, record: isRecordingSnapshots)
  }

  func testSuperMechanicalDarkMode() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      digitStyle: .disk
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .dark, record: isRecordingSnapshots)
  }

  func testSuperElectronicDarkMode() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 189.00,
      waitingDuration: 600,
      distanceMeters: 5000,
      isNight: true
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .dark, record: isRecordingSnapshots)
  }

  // MARK: - City/Vehicle Label in Top Bezel

  func testSuperMechanicalWithCityVehicleLabel() {
    let view = SuperFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      digitStyle: .disk,
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testSuperElectronicWithCityVehicleLabel() {
    let view = SuperElectronicFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      waitingDuration: 180,
      distanceMeters: 2800,
      isNight: false,
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testGoldenEagleWithCityVehicleLabel() {
    let view = GoldenEagleFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      waitingDuration: 180,
      distanceMeters: 2800,
      isNight: false,
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }

  func testBrightDigitalWithCityVehicleLabel() {
    let view = BrightDigitalFullMeterPanel(
      tripState: .inProgress,
      fare: 126.50,
      waitingDuration: 180,
      distanceMeters: 2800,
      cityVehicleLabel: "Bengaluru · Auto Rickshaw"
    )
    .frame(width: 390, height: 500)
    .background(Color(red: 0.95, green: 0.94, blue: 0.92))

    SnapshotTestHelpers.assertSwiftUIViewSnapshot(view, size: snapshotSize, colorScheme: .light, record: isRecordingSnapshots)
  }
}
