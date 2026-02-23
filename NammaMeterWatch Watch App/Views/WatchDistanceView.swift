import SwiftUI

struct WatchDistanceView: View {
  @Environment(WatchTripStore.self) private var tripStore

  var body: some View {
    VStack(spacing: 8) {
      Text("Distance")
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)

      if tripStore.tripState == .forHire {
        Text("—")
          .font(.system(size: 36, weight: .bold, design: .monospaced))
          .foregroundStyle(.tertiary)
      } else {
        Text(tripStore.formattedDistance)
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .minimumScaleFactor(0.7)
          .lineLimit(1)

        Text("avg " + tripStore.formattedSpeed)
          .font(.system(size: 15, weight: .regular, design: .monospaced))
          .foregroundStyle(.white.opacity(0.6))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
