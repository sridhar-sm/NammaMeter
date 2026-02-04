import SwiftUI

// MARK: - Flip Sign View

struct FlipSignView: View {
  let isOnTrip: Bool

  var body: some View {
    ZStack {
      SignFace(
        title: "For Hire",
        subtitle: "ಬಾಡಿಗೆಗೆ",
        helper: "Flip to start",
        color: Theme.coral
      )
      .opacity(isOnTrip ? 0 : 1)
      .rotation3DEffect(.degrees(isOnTrip ? 180 : 0), axis: (x: 0, y: 1, z: 0))

      SignFace(
        title: "On Trip",
        subtitle: "ಪ್ರಯಾಣ",
        helper: "Tap to stop",
        color: Theme.mint
      )
      .opacity(isOnTrip ? 1 : 0)
      .rotation3DEffect(.degrees(isOnTrip ? 0 : -180), axis: (x: 0, y: 1, z: 0))
    }
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOnTrip)
  }
}

// MARK: - Sign Face

struct SignFace: View {
  let title: String
  let subtitle: String
  let helper: String
  let color: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(color)
        .frame(height: 100)
        .overlay(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)

      VStack(spacing: 6) {
        Text(title)
          .font(FontPresets.Display.hero)
          .foregroundStyle(Theme.ink)
        Text(subtitle)
          .font(FontPresets.Body.large)
          .foregroundStyle(Theme.ink.opacity(0.8))
        Text(helper)
          .font(FontPresets.Body.base)
          .foregroundStyle(Theme.ink.opacity(0.6))
      }
    }
  }
}

// MARK: - Mini Flip Sign View

struct MiniFlipSignView: View {
  let isOnTrip: Bool

  var body: some View {
    ZStack {
      MiniSignFace(
        title: "For Hire",
        subtitle: "ಬಾಡಿಗೆಗೆ",
        color: Theme.coral
      )
      .opacity(isOnTrip ? 0 : 1)
      .rotation3DEffect(.degrees(isOnTrip ? 180 : 0), axis: (x: 0, y: 1, z: 0))

      MiniSignFace(
        title: "On Trip",
        subtitle: "ಪ್ರಯಾಣ",
        color: Theme.mint
      )
      .opacity(isOnTrip ? 1 : 0)
      .rotation3DEffect(.degrees(isOnTrip ? 0 : -180), axis: (x: 0, y: 1, z: 0))
    }
    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isOnTrip)
  }
}

// MARK: - Mini Sign Face

struct MiniSignFace: View {
  let title: String
  let subtitle: String
  let color: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(color)
        .frame(height: 44)
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)

      VStack(spacing: 2) {
        Text(title)
          .font(FontPresets.Display.micro)
          .foregroundStyle(Theme.ink)
          .lineLimit(1)
        Text(subtitle)
          .font(FontPresets.Body.mini)
          .foregroundStyle(Theme.ink.opacity(0.8))
          .lineLimit(1)
      }
      .padding(.horizontal, 6)
    }
  }
}
