import SwiftUI

struct WatchRoadView: View {
  @Environment(WatchTripStore.self) private var tripStore

  var body: some View {
    VStack(spacing: 8) {
      Text("Road")
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)

      if tripStore.tripState == .forHire {
        Text("—")
          .font(.system(size: 36, weight: .bold, design: .monospaced))
          .foregroundStyle(.tertiary)
      } else if tripStore.currentRoadName.isEmpty {
        Text("—")
          .font(.system(size: 36, weight: .bold, design: .monospaced))
          .foregroundStyle(.tertiary)
      } else {
        Text(tripStore.currentRoadName)
          .font(.system(size: 18, weight: .semibold, design: .rounded))
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.7)
          .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
