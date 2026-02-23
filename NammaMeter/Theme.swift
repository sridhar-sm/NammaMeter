import SwiftUI

enum Theme {
  #if os(iOS)
  static let ink = Color(uiColor: .label)
  static let card = Color(uiColor: .secondarySystemBackground)
  #else
  static let ink = Color.primary
  static let card = Color(white: 0.11)
  #endif
  static let mango = Color(red: 1.0, green: 0.92, blue: 0.72)
  static let mint = Color(red: 0.72, green: 0.95, blue: 0.85)
  static let sky = Color(red: 0.73, green: 0.9, blue: 1.0)
  static let coral = Color(red: 1.0, green: 0.74, blue: 0.7)
  static let lime = Color(red: 0.8, green: 0.97, blue: 0.73)
  static let darkControlBackground = Color(red: 0.039, green: 0.039, blue: 0.039)

  static let backgroundGradient = LinearGradient(
    colors: [mango, sky, mint],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let darkBackgroundGradient = LinearGradient(
    colors: [
      Color(red: 0.10, green: 0.10, blue: 0.10),
      Color(red: 0.13, green: 0.11, blue: 0.11),
      Color(red: 0.12, green: 0.12, blue: 0.12)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static func pastelShadow() -> Color {
    Color.black.opacity(0.12)
  }
}

extension Font {
  static func nammaDisplay(_ size: CGFloat) -> Font {
    .custom("AvenirNext-DemiBold", size: size)
  }

  static func nammaBody(_ size: CGFloat) -> Font {
    .custom("AvenirNext-Regular", size: size)
  }
}

struct NammaBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    GeometryReader { geo in
      ZStack {
        if colorScheme == .dark {
          Theme.darkBackgroundGradient
        } else {
          Theme.backgroundGradient
        }

      }
      .ignoresSafeArea()
    }
  }
}

struct CardModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(Theme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .shadow(color: Theme.pastelShadow(), radius: 12, x: 0, y: 6)
  }
}

extension View {
  func cardStyle() -> some View {
    modifier(CardModifier())
  }
}
