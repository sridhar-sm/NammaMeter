import SwiftUI
import XCTest
@testable import NammaMeter

final class ThemeAccessibilityTests: XCTestCase {
  func testContrastLightMode() {
    assertContrast(
      samples: [
        .init(name: "Primary on card", text: ThemeColors.Text.primary, background: ThemeColors.card, minimum: 4.5),
        .init(name: "Secondary on card", text: ThemeColors.Text.secondary, background: ThemeColors.card, minimum: 3.0),
        .init(name: "Hint on card", text: ThemeColors.Text.hint, background: ThemeColors.card, minimum: 3.0)
      ],
      style: .light
    )
  }

  func testContrastDarkMode() {
    assertContrast(
      samples: [
        .init(name: "Primary on card", text: ThemeColors.Text.primary, background: ThemeColors.card, minimum: 4.5),
        .init(name: "Secondary on card", text: ThemeColors.Text.secondary, background: ThemeColors.card, minimum: 3.0),
        .init(name: "Hint on card", text: ThemeColors.Text.hint, background: ThemeColors.card, minimum: 3.0)
      ],
      style: .dark
    )
  }

  private struct ContrastSample {
    let name: String
    let text: Color
    let background: Color
    let minimum: CGFloat
  }

  private func assertContrast(
    samples: [ContrastSample],
    style: UIUserInterfaceStyle,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    for sample in samples {
      let ratio = contrastRatio(text: sample.text, background: sample.background, style: style)
      let ratioText = String(format: "%.2f", ratio)
      XCTAssertGreaterThanOrEqual(
        ratio,
        sample.minimum,
        "\(sample.name) contrast ratio \(ratioText) below \(sample.minimum)",
        file: file,
        line: line
      )
    }
  }

  private func contrastRatio(text: Color, background: Color, style: UIUserInterfaceStyle) -> CGFloat {
    let fg = rgba(resolved(text, style: style))
    let bg = rgba(resolved(background, style: style))
    let blended = blend(foreground: fg, background: bg)
    let l1 = luminance(blended)
    let l2 = luminance(bg)
    let lighter = max(l1, l2)
    let darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)
  }

  private func resolved(_ color: Color, style: UIUserInterfaceStyle) -> UIColor {
    let uiColor = UIColor(color)
    return uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
  }

  private func rgba(_ color: UIColor) -> RGBA {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
      return RGBA(r: r, g: g, b: b, a: a)
    }

    var white: CGFloat = 0
    if color.getWhite(&white, alpha: &a) {
      return RGBA(r: white, g: white, b: white, a: a)
    }

    return RGBA(r: 0, g: 0, b: 0, a: 1)
  }

  private func luminance(_ rgba: RGBA) -> CGFloat {
    func channel(_ value: CGFloat) -> CGFloat {
      value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    let r = channel(rgba.r)
    let g = channel(rgba.g)
    let b = channel(rgba.b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
  }

  private func blend(foreground: RGBA, background: RGBA) -> RGBA {
    guard foreground.a < 1 else { return foreground }
    let outA = foreground.a + background.a * (1 - foreground.a)
    guard outA > 0 else { return RGBA(r: 0, g: 0, b: 0, a: 0) }

    let r = (foreground.r * foreground.a + background.r * background.a * (1 - foreground.a)) / outA
    let g = (foreground.g * foreground.a + background.g * background.a * (1 - foreground.a)) / outA
    let b = (foreground.b * foreground.a + background.b * background.a * (1 - foreground.a)) / outA
    return RGBA(r: r, g: g, b: b, a: outA)
  }

  private struct RGBA {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
  }
}
