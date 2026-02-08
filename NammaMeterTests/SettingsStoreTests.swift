import Testing
import Foundation
@testable import NammaMeter

@MainActor
@Suite("SettingsStore Tests")
struct SettingsStoreTests {

  // MARK: - Meter Display Preferences Persistence

  @Test("Meter face style persists to UserDefaults")
  func meterFaceStylePersistence() async {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-settings-\(UUID().uuidString).json")
    let defaults = UserDefaults.standard

    // Clear any existing value
    defaults.removeObject(forKey: "meterFaceStyle")

    let store = SettingsStore(fileURL: tempURL)
    // Wait for automatic load to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify default value
    #expect(store.meterFaceStyle == MeterFaceStyle.superMeter.rawValue)

    // Change the value
    store.meterFaceStyle = MeterFaceStyle.digital.rawValue

    // Verify it was persisted
    #expect(defaults.string(forKey: "meterFaceStyle") == MeterFaceStyle.digital.rawValue)

    // Cleanup
    defaults.removeObject(forKey: "meterFaceStyle")
    try? FileManager.default.removeItem(at: tempURL)
  }

  @Test("Meter render mode persists to UserDefaults")
  func meterRenderModePersistence() async {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-settings-\(UUID().uuidString).json")
    let defaults = UserDefaults.standard

    // Clear any existing value
    defaults.removeObject(forKey: "meterRenderMode")

    let store = SettingsStore(fileURL: tempURL)
    // Wait for automatic load to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify default value
    #expect(store.meterRenderMode == MeterRenderMode.full.rawValue)

    // Change the value
    store.meterRenderMode = MeterRenderMode.displayOnly.rawValue

    // Verify it was persisted
    #expect(defaults.string(forKey: "meterRenderMode") == MeterRenderMode.displayOnly.rawValue)

    // Cleanup
    defaults.removeObject(forKey: "meterRenderMode")
    try? FileManager.default.removeItem(at: tempURL)
  }

  @Test("Digit wheel style persists to UserDefaults")
  func digitWheelStylePersistence() async {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-settings-\(UUID().uuidString).json")
    let defaults = UserDefaults.standard

    // Clear any existing value
    defaults.removeObject(forKey: "digitWheelStyle")

    let store = SettingsStore(fileURL: tempURL)
    // Wait for automatic load to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify default value
    #expect(store.digitWheelStyle == DigitWheelStyle.disk.rawValue)

    // Change the value
    store.digitWheelStyle = DigitWheelStyle.drum.rawValue

    // Verify it was persisted
    #expect(defaults.string(forKey: "digitWheelStyle") == DigitWheelStyle.drum.rawValue)

    // Cleanup
    defaults.removeObject(forKey: "digitWheelStyle")
    try? FileManager.default.removeItem(at: tempURL)
  }

  @Test("Meter preferences restore from UserDefaults on init")
  func meterPreferencesRestore() async {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-settings-\(UUID().uuidString).json")
    let defaults = UserDefaults.standard

    // Set values in UserDefaults before creating the store
    defaults.set(MeterFaceStyle.goldenEagle.rawValue, forKey: "meterFaceStyle")
    defaults.set(MeterRenderMode.displayOnly.rawValue, forKey: "meterRenderMode")
    defaults.set(DigitWheelStyle.drum.rawValue, forKey: "digitWheelStyle")

    // Create new store - it should load these values during init
    let store = SettingsStore(fileURL: tempURL)
    // Wait for automatic load to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify values were restored
    #expect(store.meterFaceStyle == MeterFaceStyle.goldenEagle.rawValue)
    #expect(store.meterRenderMode == MeterRenderMode.displayOnly.rawValue)
    #expect(store.digitWheelStyle == DigitWheelStyle.drum.rawValue)

    // Cleanup
    defaults.removeObject(forKey: "meterFaceStyle")
    defaults.removeObject(forKey: "meterRenderMode")
    defaults.removeObject(forKey: "digitWheelStyle")
    try? FileManager.default.removeItem(at: tempURL)
  }

  @Test("Meter preferences use defaults when not stored")
  func meterPreferencesDefaults() async {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-settings-\(UUID().uuidString).json")
    let defaults = UserDefaults.standard

    // Ensure no stored values
    defaults.removeObject(forKey: "meterFaceStyle")
    defaults.removeObject(forKey: "meterRenderMode")
    defaults.removeObject(forKey: "digitWheelStyle")

    let store = SettingsStore(fileURL: tempURL)
    // Wait for automatic load to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify default values
    #expect(store.meterFaceStyle == MeterFaceStyle.superMeter.rawValue)
    #expect(store.meterRenderMode == MeterRenderMode.full.rawValue)
    #expect(store.digitWheelStyle == DigitWheelStyle.disk.rawValue)

    // Cleanup
    try? FileManager.default.removeItem(at: tempURL)
  }
}
