import SwiftUI

enum Theme {
  static let ink = Color(red: 0.15, green: 0.15, blue: 0.2)
  static let mango = Color(red: 1.0, green: 0.92, blue: 0.72)
  static let mint = Color(red: 0.72, green: 0.95, blue: 0.85)
  static let sky = Color(red: 0.73, green: 0.9, blue: 1.0)
  static let coral = Color(red: 1.0, green: 0.74, blue: 0.7)
  static let lime = Color(red: 0.8, green: 0.97, blue: 0.73)
  static let card = Color.white.opacity(0.85)

  static let backgroundGradient = LinearGradient(
    colors: [mango, sky, mint],
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
  var body: some View {
    GeometryReader { geo in
      ZStack {
        Theme.backgroundGradient

        Circle()
          .fill(Theme.coral.opacity(0.35))
          .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
          .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.35)
          .blur(radius: 20)

        Circle()
          .fill(Theme.lime.opacity(0.35))
          .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
          .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.15)
          .blur(radius: 20)

        RoundedRectangle(cornerRadius: 48)
          .fill(Color.white.opacity(0.12))
          .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.5)
          .rotationEffect(.degrees(8))
          .offset(y: geo.size.height * 0.2)
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
