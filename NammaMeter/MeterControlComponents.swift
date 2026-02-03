import SwiftUI

// MARK: - Control Bar Metrics

struct ControlBarMetrics {
  let tileSize: CGSize
  let iconSize: CGFloat
}

// MARK: - Control Tile

struct ControlTile<Content: View>: View {
  let background: Color
  let size: CGSize
  let content: Content

  init(background: Color, size: CGSize, @ViewBuilder content: () -> Content) {
    self.background = background
    self.size = size
    self.content = content()
  }

  var body: some View {
    content
      .frame(width: size.width, height: size.height)
      .background(background)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
  }
}

// MARK: - Mini Trip State Sign

struct MiniTripStateSign: View {
  let tripState: TripMeterState
  let metrics: ControlBarMetrics

  var body: some View {
    ControlTile(background: backgroundColor.opacity(0.85), size: metrics.tileSize) {
      Image(systemName: iconName)
        .font(.system(size: metrics.iconSize, weight: .semibold))
        .foregroundStyle(Theme.ink)
    }
  }

  private var iconName: String {
    switch tripState {
    case .forHire:
      return "play.fill"
    case .inProgress:
      return "stop.fill"
    case .complete:
      return "arrow.counterclockwise"
    }
  }

  private var backgroundColor: Color {
    switch tripState {
    case .forHire:
      return Theme.coral
    case .inProgress:
      return Theme.mint
    case .complete:
      return Theme.mango
    }
  }
}

// MARK: - Condition Tile Button

struct ConditionTileButton: View {
  let systemImage: String
  let label: String
  @Binding var isOn: Bool
  var isInteractive: Bool = true
  let metrics: ControlBarMetrics

  var body: some View {
    if isInteractive {
      Button {
        isOn.toggle()
      } label: {
        tile
      }
      .buttonStyle(.plain)
    } else {
      tile
    }
  }

  private var tile: some View {
    ControlTile(background: isOn ? Theme.coral.opacity(0.85) : Theme.card.opacity(0.9), size: metrics.tileSize) {
      Image(systemName: systemImage)
        .font(.system(size: metrics.iconSize, weight: .semibold))
        .foregroundStyle(Theme.ink)
    }
    .accessibilityLabel(label)
    .accessibilityValue(isOn ? "On" : "Off")
  }
}

// MARK: - Fare Info Tile

struct FareInfoTile: View {
  let valueText: String
  let labelText: String
  let size: CGSize
  let showsChevron: Bool
  let isExpanded: Bool

  var body: some View {
    VStack(spacing: 2) {
      Text(valueText)
        .font(.nammaDisplay(12))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(labelText)
        .font(.nammaBody(7))
        .lineLimit(1)
    }
    .foregroundStyle(Theme.ink)
    .frame(width: size.width, height: size.height)
    .background(Theme.mango.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
    .overlay(alignment: .topTrailing) {
      if showsChevron {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(Theme.ink.opacity(0.7))
          .padding(6)
      }
    }
  }
}

// MARK: - Mini Condition Chip

struct MiniConditionChip: View {
  let title: String
  let subtitle: String
  @Binding var isOn: Bool

  var body: some View {
    Button {
      isOn.toggle()
    } label: {
      VStack(spacing: 2) {
        Text(title)
          .font(.nammaDisplay(9))
        Text(subtitle)
          .font(.nammaBody(7))
      }
      .foregroundStyle(isOn ? Theme.ink : Theme.ink.opacity(0.6))
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background(isOn ? Theme.mango.opacity(0.6) : Theme.card)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(Theme.ink.opacity(isOn ? 0.2 : 0.1), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}
