import SwiftUI

enum ThemeColors {
  // MARK: - Core
  static let ink = Theme.ink
  static let card = Theme.card
  static let mango = Theme.mango
  static let mint = Theme.mint
  static let sky = Theme.sky
  static let coral = Theme.coral
  static let lime = Theme.lime

  enum Text {
    static let primary = Theme.ink
    static let secondary = Color(uiColor: .secondaryLabel)
    static let tertiary = Color(uiColor: .tertiaryLabel)
    static let disabled = Color.black.opacity(0.4)
    static let hint = Color(uiColor: .secondaryLabel)
  }

  enum Lines {
    static let subtle = Color.black.opacity(0.1)
    static let medium = Color.black.opacity(0.25)
    static let strong = Color.black.opacity(0.35)
  }

  enum Brand {
    static let primary = Color(red: 0.1, green: 0.32, blue: 0.7)
    static let primaryLight = Color(red: 0.15, green: 0.35, blue: 0.78)
    static let primaryDark = Color(red: 0.08, green: 0.22, blue: 0.6)
  }
}

enum MeterColorSchemes {
  enum Metal {
    static let edge = Color(red: 0.7, green: 0.7, blue: 0.68)
    static let panelLight = Color(red: 0.9, green: 0.9, blue: 0.88)
    static let panelWarm = Color(red: 0.88, green: 0.87, blue: 0.85)
    static let plate = Color(red: 0.92, green: 0.91, blue: 0.89)
    static let highlight = Color(red: 0.95, green: 0.94, blue: 0.92)
  }

  enum Labels {
    static let light = Color(red: 0.85, green: 0.85, blue: 0.82)
    static let medium = Color(red: 0.75, green: 0.75, blue: 0.72)
    static let muted = Color(red: 0.6, green: 0.6, blue: 0.58)
    static let dark = Color(red: 0.65, green: 0.65, blue: 0.62)
    static let dim = Color(red: 0.2, green: 0.2, blue: 0.22)
  }

  enum MeterShell {
    static let superDark = [
      Color(red: 0.17, green: 0.18, blue: 0.19),
      Color(red: 0.06, green: 0.06, blue: 0.07)
    ]
    static let golden = [
      Color(red: 0.78, green: 0.78, blue: 0.76),
      Color(red: 0.6, green: 0.6, blue: 0.58),
      Color(red: 0.36, green: 0.36, blue: 0.35)
    ]
    static let brightDigital = [
      Color(red: 0.14, green: 0.15, blue: 0.16),
      Color(red: 0.05, green: 0.05, blue: 0.06)
    ]
    static let digital = [Color(red: 0.09, green: 0.1, blue: 0.12), .black]
  }

  enum BrightDigital {
    static let faceTop = Color(red: 0.2, green: 0.21, blue: 0.22)
    static let faceBottom = Color(red: 0.1, green: 0.1, blue: 0.11)
    static let windowBackground = Color(red: 0.9, green: 0.9, blue: 0.88)
    static let line = ThemeColors.Lines.medium
    static let label = Color.black.opacity(0.8)
    static let panelTop = Color(red: 0.4, green: 0.06, blue: 0.06)
    static let panelBottom = Color(red: 0.2, green: 0.03, blue: 0.03)
    static let panelEdge = Color(red: 0.1, green: 0.02, blue: 0.02)
    static let text = ThemeColors.Brand.primary
    static let badgeTop = ThemeColors.Brand.primaryLight
    static let badgeBottom = ThemeColors.Brand.primaryDark
  }

  enum GoldenEagle {
    static let face = Color(red: 0.72, green: 0.73, blue: 0.70)
    static let dot = Color(red: 0.55, green: 0.56, blue: 0.54)
    static let fareRow = Color(red: 0.45, green: 0.18, blue: 0.18)
    static let distRow = Color(red: 0.15, green: 0.35, blue: 0.20)
    static let waitRow = Color(red: 0.15, green: 0.32, blue: 0.35)
    static let dialTop = Color(red: 0.08, green: 0.2, blue: 0.12)
    static let dialBottom = Color(red: 0.05, green: 0.14, blue: 0.08)
    static let dialEdge = Color(red: 0.03, green: 0.1, blue: 0.06)
    static let accentBlue = Color(red: 0.1, green: 0.26, blue: 0.6)
    static let accentGold = Color(red: 0.95, green: 0.78, blue: 0.25)
    static let caseEdge = Color(red: 0.4, green: 0.4, blue: 0.38)
    static let caseLight = Color(red: 0.7, green: 0.7, blue: 0.68)
    static let ledDim = Color(red: 0.03, green: 0.12, blue: 0.07)

    static func ledActive(isNight: Bool) -> Color {
      Color(red: 0.2, green: isNight ? 0.9 : 1.0, blue: 0.28)
    }
  }

  enum SuperMechanical {
    static let caseTop = Color(red: 0.17, green: 0.18, blue: 0.19)
    static let caseBottom = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let metalPanel = Metal.panelLight
    static let metalEdge = Metal.edge
    static let displayEdge = Color(red: 0.22, green: 0.22, blue: 0.24)
    static let printInk = Color.black.opacity(0.82)
    static let accentRed = Color(red: 0.78, green: 0.18, blue: 0.18)
    static let accentDigit = Color(red: 0.78, green: 0.16, blue: 0.18)
    static let digitInk = Color.black.opacity(0.85)
    static let displayBackground = Color(red: 0.96, green: 0.95, blue: 0.93)
    static let shadowTop = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let shadowBottom = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let highlightPanel = [
      Color(red: 0.94, green: 0.94, blue: 0.94),
      Color(red: 0.86, green: 0.86, blue: 0.86),
      Color(red: 0.97, green: 0.97, blue: 0.97)
    ]
    static let highlightPanelAlt = [
      Color(red: 0.95, green: 0.95, blue: 0.95),
      Color(red: 0.88, green: 0.88, blue: 0.88),
      Color(red: 0.98, green: 0.98, blue: 0.98)
    ]
  }

  enum SuperElectronic {
    static let metalPanel = Metal.panelWarm
    static let metalEdge = Metal.edge
    static let plateBackground = Metal.plate
    static let displayBackground = Color(red: 0.03, green: 0.04, blue: 0.05)
    static let bezel = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let labelLight = Labels.light
    static let labelMedium = Labels.medium
    static let labelDark = Labels.dark
    static let dim = Labels.dim
    static let accentBlue = Color(red: 0.2, green: 0.3, blue: 0.6)
  }

  enum Digital {
    static let bezel = Color(red: 0.18, green: 0.2, blue: 0.24)
    static let bezelAlt = Color(red: 0.2, green: 0.22, blue: 0.26)
    static let accent = Color(red: 0.15, green: 0.8, blue: 0.9)
    static let screenBackground = Color(red: 0.03, green: 0.06, blue: 0.08)
    static let button = Color(red: 0.18, green: 0.19, blue: 0.22)
  }

  enum LED {
    static let red = Color(red: 1.0, green: 0.2, blue: 0.12)
    static let redDim = Color(red: 0.12, green: 0.06, blue: 0.06)
    static let green = Color(red: 0.2, green: 1.0, blue: 0.25)
    static let greenDim = Color(red: 0.06, green: 0.12, blue: 0.07)
    static let amber = Color(red: 1.0, green: 0.65, blue: 0.0)
    static let amberDim = Color(red: 0.12, green: 0.08, blue: 0.04)
    static let blue = Color(red: 0.2, green: 0.5, blue: 1.0)
    static let blueDim = Color(red: 0.06, green: 0.08, blue: 0.12)
    static let white = Color(red: 1.0, green: 1.0, blue: 0.95)
    static let whiteDim = Color(red: 0.12, green: 0.12, blue: 0.11)
    static let labelLight = Labels.medium
    static let labelMuted = Labels.muted
    static let background = Color(red: 0.03, green: 0.04, blue: 0.05)
    static let bezel = Color(red: 0.12, green: 0.12, blue: 0.14)
  }
}
