import SwiftUI

struct MeterSettingsSheetView: View {
  @Binding var meterFaceStyle: MeterFaceStyle
  @Binding var meterRenderMode: MeterRenderMode
  @Binding var digitWheelStyle: DigitWheelStyle
  @Binding var isPresented: Bool

  var body: some View {
    NavigationStack {
      Form {
        meterSettingsSections
      }
      .navigationTitle("Meter Settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            isPresented = false
          }
        }
      }
    }
  }

  @ViewBuilder
  private var meterSettingsSections: some View {
    Section("Meter Style") {
      ForEach(MeterFaceStyle.allCases) { style in
        Button {
          meterFaceStyle = style
        } label: {
          HStack {
            Label(style.label, systemImage: style.systemImage)
            Spacer()
            if meterFaceStyle == style {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.ink)
            }
          }
        }
      }
    }
    Section("Display Mode") {
      ForEach(MeterRenderMode.allCases) { mode in
        Button {
          meterRenderMode = mode
        } label: {
          HStack {
            Text(mode.label)
            Spacer()
            if meterRenderMode == mode {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.ink)
            }
          }
        }
      }
    }
    if meterFaceStyle.capabilities.isMechanical {
      Section("Digit Style") {
        ForEach(DigitWheelStyle.allCases) { style in
          Button {
            digitWheelStyle = style
          } label: {
            HStack {
              Text(style.label)
              Spacer()
              if digitWheelStyle == style {
                Image(systemName: "checkmark")
                  .foregroundStyle(Theme.ink)
              }
            }
          }
        }
      }
    }
  }
}
