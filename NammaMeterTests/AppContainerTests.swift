import XCTest
@testable import NammaMeter

@MainActor
final class AppContainerTests: XCTestCase {

  func testDefaultInitializationCreatesAllStores() {
    let container = AppContainer()

    XCTAssertNotNil(container.settingsStore)
    XCTAssertNotNil(container.tripStore)
    XCTAssertNotNil(container.meterStore)
  }

  func testPreviewContainerUsesIsolatedStores() {
    let preview1 = AppContainer.preview
    let preview2 = AppContainer.preview

    // Each preview should get distinct store instances
    XCTAssertFalse(preview1.settingsStore === preview2.settingsStore)
    XCTAssertFalse(preview1.tripStore === preview2.tripStore)
    XCTAssertFalse(preview1.meterStore === preview2.meterStore)
  }

  func testCustomInitializationAcceptsInjectedStores() {
    let settings = SettingsStore()
    let trips = TripStore()
    let meter = MeterStore()

    let container = AppContainer(
      settingsStore: settings,
      tripStore: trips,
      meterStore: meter
    )

    XCTAssertTrue(container.settingsStore === settings)
    XCTAssertTrue(container.tripStore === trips)
    XCTAssertTrue(container.meterStore === meter)
  }
}
