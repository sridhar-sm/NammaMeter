import CoreLocation
import Foundation
import SwiftUI
import UIKit

struct MeterView: View {
  @Environment(SettingsStore.self) private var settingsStore
  @Environment(TripStore.self) private var tripStore
  @Environment(MeterStore.self) private var meterStore
  @Environment(\.openURL) private var openURL
  @State private var showLocationAlert = false
  @State private var showAlwaysPrompt = false
  @State private var showMeterSettings = false
  @State private var pagerSelection = 0
  @State private var meterFaceStyle: MeterFaceStyle = .superMeter
  @State private var meterRenderMode: MeterRenderMode = .full
  @State private var digitWheelStyle: DigitWheelStyle = .disk
  @State private var hasPromptedForAlways = false

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
        meterStore.requestAuthorization()
        meterStore.refreshTimeBasedConditions()
        if meterStore.authorizationStatus == .denied || meterStore.authorizationStatus == .restricted {
          showLocationAlert = true
        }
      }
      .onChange(of: meterStore.isOnTrip) { _, isOnTrip in
        if isOnTrip {
          hasPromptedForAlways = false
          evaluateAlwaysPrompt()
        } else {
          showAlwaysPrompt = false
        }
      }
      .onChange(of: meterStore.authorizationStatus) { _, newStatus in
        if newStatus == .denied || newStatus == .restricted {
          showLocationAlert = true
        } else if newStatus == .authorizedAlways {
          showAlwaysPrompt = false
        }
        evaluateAlwaysPrompt()
      }
      .alert("Location access needed", isPresented: $showLocationAlert) {
        Button("Open Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
        Button("Not Now", role: .cancel) { }
      } message: {
        Text("Enable location to track distance and replay routes.")
      }
      .alert("Enable background tracking", isPresented: $showAlwaysPrompt) {
        Button("Enable Always") {
          meterStore.requestAlwaysAuthorization()
        }
        Button("Open Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
        Button("Not Now", role: .cancel) { }
      } message: {
        Text("Allow Always location access to keep tracking distance when the app is in the background.")
      }
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

  // MARK: - Helpers

  private func evaluateAlwaysPrompt() {
    guard meterStore.isOnTrip else { return }
    guard meterStore.authorizationStatus == .authorizedWhenInUse else { return }
    guard !hasPromptedForAlways else { return }
    hasPromptedForAlways = true
    showAlwaysPrompt = true
  }
}

#Preview {
  MeterView()
    .environment(SettingsStore())
    .environment(TripStore())
    .environment(MeterStore())
}
