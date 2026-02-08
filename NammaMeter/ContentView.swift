import SwiftUI

struct ContentView: View {
  @Environment(SettingsStore.self) private var settingsStore

  var body: some View {
    TabView {
      MeterView()
        .tabItem {
          TabLabel(title: "Meter", subtitle: "ಮೀಟರ್", systemImage: "speedometer")
        }

      HistoryView()
        .tabItem {
          TabLabel(title: "Trips", subtitle: "ಪ್ರಯಾಣಗಳು", systemImage: "clock.arrow.circlepath")
        }

      SettingsView()
        .tabItem {
          TabLabel(title: "Settings", subtitle: "ಸೆಟ್ಟಿಂಗ್‌ಗಳು", systemImage: "slider.horizontal.3")
        }
    }
    .tint(Theme.ink)
    .preferredColorScheme(colorScheme(for: settingsStore.themePreference))
  }

  private func colorScheme(for preference: String) -> ColorScheme? {
    switch preference {
    case "light":
      return .light
    case "dark":
      return .dark
    default:
      return nil // System preference
    }
  }
}

struct TabLabel: View {
  let title: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: systemImage)
      Text(title)
        .font(FontPresets.Body.base)
      Text(subtitle)
        .font(FontPresets.Body.xSmall)
    }
  }
}

#Preview {
  ContentView()
    .environment(AppContainer.preview)
}
