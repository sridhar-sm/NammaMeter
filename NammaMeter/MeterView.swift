import SwiftUI

struct MeterView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(TripStore.self) private var tripStore
  @Environment(MeterStore.self) private var meterStore
  @State private var showMeterSettings = false
  @State private var pagerSelection = 0
  @State private var meterFaceStyle: MeterFaceStyle = .superMeter
  @State private var meterRenderMode: MeterRenderMode = .full
  @State private var digitWheelStyle: DigitWheelStyle = .disk

  var body: some View {
    NavigationStack {
      ZStack {
        NammaBackground()
        mapArea
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .ignoresSafeArea(edges: .top)
          .padding(.bottom, 16)
      }
      .onAppear {
        if !TestEnvironment.isRunningTests {
          meterStore.requestAuthorization()
        }
        meterStore.refreshTimeBasedConditions()
      }
      .withLocationPermissionHandling(coordinator: meterStore.locationPermissionCoordinator)
      .sheet(isPresented: $showMeterSettings) {
        meterSettingsSheet
      }
    }
  }

  // MARK: - Layout

  private var mapArea: some View {
    MeterLayoutContainer(
      pagerSelection: $pagerSelection,
      meterFaceStyle: $meterFaceStyle,
      meterRenderMode: $meterRenderMode,
      digitWheelStyle: $digitWheelStyle,
      showMeterSettings: $showMeterSettings
    )
  }

  // MARK: - Settings Sheet

  private var meterSettingsSheet: some View {
    MeterSettingsSheetView(
      meterFaceStyle: $meterFaceStyle,
      meterRenderMode: $meterRenderMode,
      digitWheelStyle: $digitWheelStyle,
      isPresented: $showMeterSettings
    )
  }

}

#Preview {
  MeterView()
    .environment(SettingsStore())
    .environment(TripStore())
    .environment(MeterStore())
}
