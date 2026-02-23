import Combine
import SwiftUI

@main
struct NammaMeterApp: App {
  @State private var container: AppContainer

  init() {
    if TestEnvironment.shouldResetState {
      try? FileManager.default.removeItem(at: SettingsStore.defaultURL)
      try? FileManager.default.removeItem(at: TripStore.defaultURL)
    }
    _container = State(initialValue: AppContainer())
  }

  var body: some Scene {
    WindowGroup {
      if TestEnvironment.isRunningHostedUnitTests {
        UnitTestHostView()
      } else {
        ContentView()
          .environment(container)
          .modifier(ScreenAwakeSyncModifier(
            screenAwakeManager: container.screenAwakeManager,
            settingsStore: container.settingsStore,
            meterStore: container.meterStore
          ))
          .modifier(WatchConnectivitySyncModifier(
            connectivityService: container.connectivityService,
            settingsStore: container.settingsStore,
            meterStore: container.meterStore,
            tripStore: container.tripStore
          ))
      }
    }
  }
}

private struct UnitTestHostView: View {
  var body: some View {
    Color.clear
      .ignoresSafeArea()
  }
}

struct WatchConnectivitySyncModifier: ViewModifier {
  let connectivityService: PhoneConnectivityService
  let settingsStore: SettingsStore
  let meterStore: MeterStore
  let tripStore: TripStore

  private let periodicTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

  func body(content: Content) -> some View {
    content
      // Push config when city, vehicle, meter style, or favorites change
      .onChange(of: settingsStore.selectedCityId) { _, _ in
        connectivityService.sendConfig(from: settingsStore)
      }
      .onChange(of: settingsStore.selectedVehicleType) { _, _ in
        connectivityService.sendConfig(from: settingsStore)
      }
      .onChange(of: settingsStore.meterFaceStyle) { _, _ in
        connectivityService.sendConfig(from: settingsStore)
      }
      .onChange(of: settingsStore.digitWheelStyle) { _, _ in
        connectivityService.sendConfig(from: settingsStore)
      }
      .onChange(of: settingsStore._favoritesVersion) { _, _ in
        connectivityService.sendConfig(from: settingsStore)
      }
      // State transitions: send immediately (force bypasses throttle + thresholds)
      .onChange(of: meterStore.tripState) { _, newState in
        if newState == .complete, let trip = tripStore.trips.first {
          connectivityService.sendCompletedTrip(trip)
        }
        connectivityService.sendTripUpdate(from: meterStore, settingsStore: settingsStore, force: true)
      }
      // Periodic poll during active trips; sendTripUpdate skips if no threshold exceeded
      .onReceive(periodicTimer) { _ in
        if meterStore.tripState == .inProgress {
          connectivityService.sendTripUpdate(from: meterStore, settingsStore: settingsStore)
        }
      }
      // Push initial config on appear
      .onAppear {
        connectivityService.sendConfig(from: settingsStore)
      }
      // Push config when Watch becomes reachable
      .onChange(of: connectivityService.isWatchReachable) { _, reachable in
        if reachable {
          connectivityService.sendConfig(from: settingsStore)
        }
      }
  }
}

struct ScreenAwakeSyncModifier: ViewModifier {
  let screenAwakeManager: ScreenAwakeManager
  let settingsStore: SettingsStore
  let meterStore: MeterStore

  func body(content: Content) -> some View {
    content
      .onChange(of: settingsStore.settings.keepScreenAwakeDuringTrip) { _, newValue in
        screenAwakeManager.isEnabled = newValue
      }
      .onChange(of: meterStore.tripState) { _, newState in
        screenAwakeManager.tripState = newState
      }
      .onAppear {
        screenAwakeManager.isEnabled = settingsStore.settings.keepScreenAwakeDuringTrip
        screenAwakeManager.tripState = meterStore.tripState
      }
  }
}
