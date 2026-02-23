import SwiftUI

struct WatchWaitingView: View {
  @Environment(WatchTripStore.self) private var tripStore

  var body: some View {
    VStack(spacing: 8) {
      Text("Waiting")
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)

      if tripStore.tripState == .forHire {
        Text("—")
          .font(.system(size: 36, weight: .bold, design: .monospaced))
          .foregroundStyle(.tertiary)
      } else {
        Text(tripStore.formattedWaiting)
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .minimumScaleFactor(0.7)
          .lineLimit(1)

        if tripStore.isWaiting {
          HStack(spacing: 4) {
            Circle()
              .fill(.yellow)
              .frame(width: 6, height: 6)
            Text("Waiting")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.yellow)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
