import SwiftUI

enum FontPresets {
  enum Display {
    static let hero = Font.nammaDisplay(22)
    static let title = Font.nammaDisplay(20)
    static let header = Font.nammaDisplay(18)
    static let subhead = Font.nammaDisplay(16)
    static let detail = Font.nammaDisplay(15)
    static let label = Font.nammaDisplay(14)
    static let caption = Font.nammaDisplay(13)
    static let small = Font.nammaDisplay(12)
    static let tiny = Font.nammaDisplay(11)
    static let micro = Font.nammaDisplay(10)
    static let mini = Font.nammaDisplay(9)
  }

  enum Body {
    static let large = Font.nammaBody(14)
    static let medium = Font.nammaBody(13)
    static let base = Font.nammaBody(12)
    static let small = Font.nammaBody(11)
    static let xSmall = Font.nammaBody(10)
    static let micro = Font.nammaBody(9)
    static let mini = Font.nammaBody(7)
  }

  static let pageTitle = Display.title
  static let sectionHeader = Display.header
  static let cardTitle = Display.subhead
  static let cardBody = Body.base
  static let fieldLabel = Display.small
  static let helperText = Body.small
  static let badgeLabel = Body.xSmall
}
