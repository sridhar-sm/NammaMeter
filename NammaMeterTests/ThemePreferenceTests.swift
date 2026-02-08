import XCTest
@testable import NammaMeter

final class ThemePreferenceTests: XCTestCase {

  override func setUp() async throws {
    try await super.setUp()
    // Clear UserDefaults for this test
    UserDefaults.standard.removeObject(forKey: "themePreference")
  }

  override func tearDown() async throws {
    try await super.tearDown()
    UserDefaults.standard.removeObject(forKey: "themePreference")
  }

  func testThemePreferenceDefaultsToSystem() async {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    let preference = await MainActor.run {
      settingsStore.themePreference
    }
    XCTAssertEqual(preference, "system", "Theme preference should default to 'system'")
  }

  func testCanSetThemePreferenceToLight() async {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    await MainActor.run {
      settingsStore.themePreference = "light"
    }

    let preference = await MainActor.run {
      settingsStore.themePreference
    }
    XCTAssertEqual(preference, "light", "Theme preference should be settable to 'light'")
  }

  func testCanSetThemePreferenceToDark() async {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    await MainActor.run {
      settingsStore.themePreference = "dark"
    }

    let preference = await MainActor.run {
      settingsStore.themePreference
    }
    XCTAssertEqual(preference, "dark", "Theme preference should be settable to 'dark'")
  }

  func testCanSetThemePreferenceToSystem() async {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    await MainActor.run {
      settingsStore.themePreference = "light"
      settingsStore.themePreference = "system"
    }

    let preference = await MainActor.run {
      settingsStore.themePreference
    }
    XCTAssertEqual(preference, "system", "Theme preference should be settable back to 'system'")
  }

  func testThemePreferencePersistsToUserDefaults() async {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    await MainActor.run {
      settingsStore.themePreference = "dark"
    }

    let storedValue = UserDefaults.standard.string(forKey: "themePreference")
    XCTAssertEqual(storedValue, "dark", "Theme preference should persist to UserDefaults")
  }

  func testThemePreferenceLoadsFromUserDefaults() async {
    // Set preference in UserDefaults directly
    UserDefaults.standard.set("light", forKey: "themePreference")

    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")

    // Create a new SettingsStore instance
    let newStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    // The new store should read the preference from UserDefaults
    let preference = await MainActor.run {
      newStore.themePreference
    }
    XCTAssertEqual(preference, "light", "Theme preference should load from UserDefaults")
  }

  func testThemePreferenceHandlesInvalidValues() async {
    // Set an invalid value in UserDefaults
    UserDefaults.standard.set("invalid", forKey: "themePreference")

    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    let preference = await MainActor.run {
      settingsStore.themePreference
    }
    // The property should return whatever was set (validation is done at the UI level)
    XCTAssertEqual(preference, "invalid", "Theme preference should return the stored value regardless of validity")
  }

  func testMultipleThemePreferenceChanges() async {
    let themes = ["light", "dark", "system", "light", "dark"]

    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let settingsStore = await MainActor.run {
      SettingsStore(fileURL: tempURL)
    }

    for (index, theme) in themes.enumerated() {
      await MainActor.run {
        settingsStore.themePreference = theme
      }

      let preference = await MainActor.run {
        settingsStore.themePreference
      }
      XCTAssertEqual(preference, theme, "Theme preference should update correctly at iteration \(index)")

      let storedValue = UserDefaults.standard.string(forKey: "themePreference")
      XCTAssertEqual(storedValue, theme, "UserDefaults should reflect the change at iteration \(index)")
    }
  }
}
