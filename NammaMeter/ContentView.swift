import SwiftUI

struct ContentView: View {
  @State private var showSettings = false

  var body: some View {
    TabView {
      MeterView(showSettings: $showSettings)
        .tabItem {
          TabLabel(title: "Meter", subtitle: "ಮೀಟರ್", systemImage: "speedometer")
        }

      HistoryView()
        .tabItem {
          TabLabel(title: "Trips", subtitle: "ಪ್ರಯಾಣಗಳು", systemImage: "clock.arrow.circlepath")
        }
    }
    .tint(Theme.ink)
    .sheet(isPresented: $showSettings) {
      SettingsView()
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
        .font(.nammaBody(12))
      Text(subtitle)
        .font(.nammaBody(10))
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(SettingsStore())
    .environmentObject(TripStore())
}
