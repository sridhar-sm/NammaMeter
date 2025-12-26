import SwiftUI

struct ContentView: View {
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
        .font(.nammaBody(12))
      Text(subtitle)
        .font(.nammaBody(10))
    }
  }
}

#Preview {
  ContentView()
    .environment(SettingsStore())
    .environment(TripStore())
}
