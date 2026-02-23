import SwiftUI

struct WatchContentView: View {
  @Environment(WatchTripStore.self) private var tripStore
  @Environment(WatchConnectivityService.self) private var connectivity

  var body: some View {
    TabView {
      WatchFareView()
      WatchRoadView()
      WatchTimeView()
      WatchDistanceView()
      WatchWaitingView()
      WatchFavoritesView()
    }
    .tabViewStyle(.verticalPage)
    .overlay {
      if tripStore.config == nil || !connectivity.isPhoneReachable {
        phoneNotReachableView
      }
    }
  }

  private var phoneNotReachableView: some View {
    VStack(spacing: 8) {
      Image(systemName: "iphone.slash")
        .font(.system(size: 28))
        .foregroundStyle(.orange)
      Text("Open NammaMeter\non iPhone")
        .font(.system(size: 14, weight: .medium, design: .rounded))
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black.opacity(0.92))
  }
}
