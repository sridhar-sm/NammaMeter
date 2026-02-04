import SwiftUI

// MARK: - LED Color Scheme

/// Defines the active and dim colors for LED displays.
/// Use presets for common LED colors or create custom schemes.
struct LEDColorScheme: Equatable, Sendable {
    let active: Color
    let dim: Color

    // Common LED color presets
    static let red = LEDColorScheme(
        active: ThemeColors.LED.red,
        dim: ThemeColors.LED.redDim
    )

    static let green = LEDColorScheme(
        active: ThemeColors.LED.green,
        dim: ThemeColors.LED.greenDim
    )

    static let amber = LEDColorScheme(
        active: ThemeColors.LED.amber,
        dim: ThemeColors.LED.amberDim
    )

    static let blue = LEDColorScheme(
        active: ThemeColors.LED.blue,
        dim: ThemeColors.LED.blueDim
    )

    static let white = LEDColorScheme(
        active: ThemeColors.LED.white,
        dim: ThemeColors.LED.whiteDim
    )
}

// MARK: - LED Segment Shape

/// Custom shape for LED segments with pointed ends for authentic appearance.
struct LEDSegmentShape: Shape {
    let isHorizontal: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isHorizontal {
            let pointOffset = rect.height * 0.5
            path.move(to: CGPoint(x: pointOffset, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - pointOffset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - pointOffset, y: rect.maxY))
            path.addLine(to: CGPoint(x: pointOffset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        } else {
            let pointOffset = rect.width * 0.5
            path.move(to: CGPoint(x: rect.midX, y: pointOffset))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - pointOffset))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - pointOffset))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: pointOffset))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - 7-Segment Digit

/// A single 7-segment LED digit display.
/// Supports digits 0-9 and select characters (F, o, r, H, I, E, n, t, L, P, A, b, c, d, U).
struct LED7SegmentDigit: View {
    let value: LED7SegmentValue
    let height: CGFloat
    var colorScheme: LEDColorScheme = .red
    var isSmall: Bool = false

    /// Segment order: [a, b, c, d, e, f, g]
    /// a=top, b=top-right, c=bottom-right, d=bottom, e=bottom-left, f=top-left, g=middle
    private static let segmentMap: [Int: [Bool]] = [
        0: [true, true, true, true, true, true, false],
        1: [false, true, true, false, false, false, false],
        2: [true, true, false, true, true, false, true],
        3: [true, true, true, true, false, false, true],
        4: [false, true, true, false, false, true, true],
        5: [true, false, true, true, false, true, true],
        6: [true, false, true, true, true, true, true],
        7: [true, true, true, false, false, false, false],
        8: [true, true, true, true, true, true, true],
        9: [true, true, true, true, false, true, true]
    ]

    private static let letterMap: [Character: [Bool]] = [
        "F": [true, false, false, false, true, true, true],
        "o": [false, false, true, true, true, false, true],
        "r": [false, false, false, false, true, false, true],
        "H": [false, true, true, false, true, true, true],
        "I": [false, true, true, false, false, false, false],
        "E": [true, false, false, true, true, true, true],
        "n": [false, false, true, false, true, false, true],
        "t": [false, false, false, true, true, true, true],
        "L": [false, false, false, true, true, true, false],
        "P": [true, true, false, false, true, true, true],
        "A": [true, true, true, false, true, true, true],
        "b": [false, false, true, true, true, true, true],
        "c": [false, false, false, true, true, false, true],
        "d": [false, true, true, true, true, false, true],
        "U": [false, true, true, true, true, true, false],
        "-": [false, false, false, false, false, false, true]
    ]

    private var segments: [Bool] {
        switch value {
        case .digit(let d):
            return Self.segmentMap[d] ?? Array(repeating: false, count: 7)
        case .character(let c):
            return Self.letterMap[c] ?? Array(repeating: false, count: 7)
        case .blank:
            return Array(repeating: false, count: 7)
        }
    }

    var body: some View {
        let width = height * 0.6
        let segmentThickness = height * (isSmall ? 0.1 : 0.12)
        let segmentLength = height * 0.38

        ZStack {
            // Background for digit area
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.3))
                .frame(width: width, height: height)

            // Segment a (top horizontal)
            segmentView(index: 0, isHorizontal: true, length: segmentLength, thickness: segmentThickness)
                .offset(y: -height * 0.38)

            // Segment b (top right vertical)
            segmentView(index: 1, isHorizontal: false, length: segmentLength * 0.85, thickness: segmentThickness)
                .offset(x: width * 0.28, y: -height * 0.18)

            // Segment c (bottom right vertical)
            segmentView(index: 2, isHorizontal: false, length: segmentLength * 0.85, thickness: segmentThickness)
                .offset(x: width * 0.28, y: height * 0.18)

            // Segment d (bottom horizontal)
            segmentView(index: 3, isHorizontal: true, length: segmentLength, thickness: segmentThickness)
                .offset(y: height * 0.38)

            // Segment e (bottom left vertical)
            segmentView(index: 4, isHorizontal: false, length: segmentLength * 0.85, thickness: segmentThickness)
                .offset(x: -width * 0.28, y: height * 0.18)

            // Segment f (top left vertical)
            segmentView(index: 5, isHorizontal: false, length: segmentLength * 0.85, thickness: segmentThickness)
                .offset(x: -width * 0.28, y: -height * 0.18)

            // Segment g (middle horizontal)
            segmentView(index: 6, isHorizontal: true, length: segmentLength, thickness: segmentThickness)
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func segmentView(index: Int, isHorizontal: Bool, length: CGFloat, thickness: CGFloat) -> some View {
        let isActive = segments[index]
        LEDSegmentShape(isHorizontal: isHorizontal)
            .fill(isActive ? colorScheme.active : colorScheme.dim)
            .frame(width: isHorizontal ? length : thickness, height: isHorizontal ? thickness : length)
            .shadow(color: isActive ? colorScheme.active.opacity(0.7) : .clear, radius: isActive ? 4 : 0)
    }
}

/// Value to display in a 7-segment digit
enum LED7SegmentValue: Equatable, Sendable {
    case digit(Int)
    case character(Character)
    case blank
}

// MARK: - LED Decimal Point

/// A single LED decimal point or dot indicator.
struct LEDDecimalPoint: View {
    var isActive: Bool = true
    var colorScheme: LEDColorScheme = .red
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(isActive ? colorScheme.active : colorScheme.dim)
            .frame(width: size, height: size)
            .shadow(color: isActive ? colorScheme.active.opacity(0.8) : .clear, radius: isActive ? 4 : 0)
    }
}

// MARK: - LED Colon (for time displays)

/// A colon separator for time displays (two stacked dots).
struct LEDColon: View {
    var isActive: Bool = true
    var colorScheme: LEDColorScheme = .red
    let height: CGFloat

    var body: some View {
        let dotSize = height * 0.1
        VStack(spacing: height * 0.15) {
            Circle()
                .fill(isActive ? colorScheme.active : colorScheme.dim)
                .frame(width: dotSize, height: dotSize)
            Circle()
                .fill(isActive ? colorScheme.active : colorScheme.dim)
                .frame(width: dotSize, height: dotSize)
        }
        .shadow(color: isActive ? colorScheme.active.opacity(0.6) : .clear, radius: isActive ? 2 : 0)
    }
}

// MARK: - LED Digit Group

/// A group of 7-segment digits for displaying numbers or text.
/// Supports configurable digit count, decimal position, colon separator, and leading zero blanking.
struct LEDDigitGroup: View {
    let digitCount: Int
    let height: CGFloat
    var colorScheme: LEDColorScheme = .red
    var isSmall: Bool = false
    var spacing: CGFloat? = nil

    /// Position of decimal point (0-indexed from left). nil = no decimal.
    var decimalPosition: Int? = nil

    /// Position of colon (0-indexed from left, appears after this digit). nil = no colon.
    var colonPosition: Int? = nil

    /// The values to display (digit, character, or blank for each position)
    let values: [LED7SegmentValue]

    private var effectiveSpacing: CGFloat {
        spacing ?? (height * (isSmall ? 0.08 : 0.12))
    }

    var body: some View {
        HStack(spacing: effectiveSpacing) {
            ForEach(0..<digitCount, id: \.self) { index in
                let value = index < values.count ? values[index] : .blank

                LED7SegmentDigit(
                    value: value,
                    height: height,
                    colorScheme: colorScheme,
                    isSmall: isSmall
                )

                // Colon after this digit?
                if colonPosition == index {
                    LEDColon(
                        isActive: !values.allSatisfy { $0 == .blank },
                        colorScheme: colorScheme,
                        height: height
                    )
                }

                // Decimal after this digit?
                if decimalPosition == index {
                    LEDDecimalPoint(
                        isActive: !values.allSatisfy { $0 == .blank },
                        colorScheme: colorScheme,
                        size: height * (isSmall ? 0.08 : 0.12)
                    )
                    .offset(y: height * (isSmall ? 0.35 : 0.4))
                }
            }
        }
    }
}

// MARK: - LED Digit Group Helpers

extension LEDDigitGroup {
    /// Creates a digit group displaying an integer with optional leading zero blanking.
    static func forInteger(
        _ value: Int?,
        digitCount: Int,
        height: CGFloat,
        colorScheme: LEDColorScheme = .red,
        isSmall: Bool = false,
        leadingZeroBlanking: Bool = true,
        decimalPosition: Int? = nil
    ) -> LEDDigitGroup {
        var values: [LED7SegmentValue] = []

        if let value = value {
            var remaining = value
            var digits: [Int] = []

            // Extract digits from right to left
            for _ in 0..<digitCount {
                digits.insert(remaining % 10, at: 0)
                remaining /= 10
            }

            // Apply leading zero blanking
            var foundNonZero = false
            for (index, digit) in digits.enumerated() {
                if digit != 0 {
                    foundNonZero = true
                }
                // Keep last digit even if zero, blank leading zeros
                let isLastDigit = index == digits.count - 1
                let shouldBlank = leadingZeroBlanking && !foundNonZero && !isLastDigit
                values.append(shouldBlank ? .blank : .digit(digit))
            }
        } else {
            values = Array(repeating: .blank, count: digitCount)
        }

        return LEDDigitGroup(
            digitCount: digitCount,
            height: height,
            colorScheme: colorScheme,
            isSmall: isSmall,
            decimalPosition: decimalPosition,
            values: values
        )
    }

    /// Creates a digit group displaying text characters.
    static func forText(
        _ text: String,
        digitCount: Int,
        height: CGFloat,
        colorScheme: LEDColorScheme = .red,
        isSmall: Bool = false,
        alignment: HorizontalAlignment = .center
    ) -> LEDDigitGroup {
        var values: [LED7SegmentValue] = Array(repeating: .blank, count: digitCount)
        let chars = Array(text)

        let startIndex: Int
        switch alignment {
        case .leading:
            startIndex = 0
        case .trailing:
            startIndex = max(0, digitCount - chars.count)
        default: // center
            startIndex = max(0, (digitCount - chars.count) / 2)
        }

        for (i, char) in chars.enumerated() {
            let targetIndex = startIndex + i
            if targetIndex < digitCount {
                values[targetIndex] = .character(char)
            }
        }

        return LEDDigitGroup(
            digitCount: digitCount,
            height: height,
            colorScheme: colorScheme,
            isSmall: isSmall,
            values: values
        )
    }
}

// MARK: - LED Panel

/// A panel containing LED digit groups with optional labels.
/// Used to create structured displays like fare, time, or distance readouts.
struct LEDPanel<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    var leftLabel: String? = nil
    var rightLabel: String? = nil
    var labelColor: Color = ThemeColors.LED.labelLight
    let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            if let left = leftLabel {
                Text(left)
                    .font(.system(size: height * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(labelColor)
                    .frame(width: width * 0.15, alignment: .leading)
            }

            Spacer()

            content()

            Spacer()

            if let right = rightLabel {
                Text(right)
                    .font(.system(size: height * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(labelColor)
                    .frame(width: width * 0.1, alignment: .trailing)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - LED Status Indicator

/// A single LED status indicator dot with label.
struct LEDStatusIndicator: View {
    let label: String
    let isActive: Bool
    let height: CGFloat
    var colorScheme: LEDColorScheme = .red
    var labelColor: Color = ThemeColors.LED.labelMuted

    var body: some View {
        VStack(spacing: height * 0.08) {
            Circle()
                .fill(isActive ? colorScheme.active : colorScheme.dim)
                .frame(width: height * 0.22, height: height * 0.22)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: isActive ? colorScheme.active.opacity(0.8) : .clear, radius: isActive ? 6 : 0)

            Text(label)
                .font(.system(size: height * 0.14, weight: .medium, design: .rounded))
                .foregroundStyle(labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(width: height * 0.6)
    }
}

// MARK: - LED Display Container

/// A container for LED panels with standard dark background and bezel.
struct LEDDisplayContainer<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    var backgroundColor: Color = ThemeColors.LED.background
    var bezelColor: Color = ThemeColors.LED.bezel
    var cornerRadius: CGFloat? = nil
    var bezelWidth: CGFloat = 3
    let content: () -> Content

    var body: some View {
        let radius = cornerRadius ?? (width * 0.03)

        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(bezelColor, lineWidth: bezelWidth)
            )
            .frame(width: width, height: height)
            .overlay(content())
    }
}

// MARK: - Previews

#Preview("LED Colors") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            LED7SegmentDigit(value: .digit(8), height: 60, colorScheme: .red)
            LED7SegmentDigit(value: .digit(8), height: 60, colorScheme: .green)
            LED7SegmentDigit(value: .digit(8), height: 60, colorScheme: .amber)
            LED7SegmentDigit(value: .digit(8), height: 60, colorScheme: .blue)
        }

        HStack(spacing: 20) {
            LEDDigitGroup.forInteger(123, digitCount: 4, height: 50, colorScheme: .red)
            LEDDigitGroup.forInteger(45, digitCount: 4, height: 50, colorScheme: .green, leadingZeroBlanking: true)
        }

        LEDDigitGroup.forText("HI", digitCount: 4, height: 50, colorScheme: .amber)
    }
    .padding()
    .background(Color.black)
}

#Preview("Digit Group with Decimal") {
    VStack(spacing: 20) {
        // Fare display: 123.45
        HStack(spacing: 8) {
            LEDDigitGroup.forInteger(123, digitCount: 3, height: 60, decimalPosition: 2)
            LEDDigitGroup.forInteger(45, digitCount: 2, height: 60, leadingZeroBlanking: false)
        }

        // Time display: 12:34
        LEDDigitGroup(
            digitCount: 4,
            height: 50,
            colonPosition: 1,
            values: [.digit(1), .digit(2), .digit(3), .digit(4)]
        )
    }
    .padding()
    .background(Color.black)
}
