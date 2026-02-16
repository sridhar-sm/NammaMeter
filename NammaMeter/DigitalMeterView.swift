import CoreLocation
import SwiftUI

// MARK: - Neo LCD Meter

private enum NeoLCDPage: Int, CaseIterable {
  case fare
  case fareCard
}

private struct NeoLCDTheme {
  let windowBackground: Color
  let bezel: Color
  let rowBackground: Color
  let rowBorder: Color
  let panelBackground: Color
  let panelBorder: Color
  let topBarBackground: Color
  let topBarText: Color
  let nightIconActive: Color
  let labelText: Color
  let valueText: Color
  let separator: Color
  let activeRuleHighlight: Color
  let inactiveRuleText: Color

  static func palette(for colorScheme: ColorScheme) -> NeoLCDTheme {
    if colorScheme == .dark {
      return NeoLCDTheme(
        windowBackground: Color(red: 0.06, green: 0.08, blue: 0.1),
        bezel: Color(red: 0.18, green: 0.2, blue: 0.24),
        rowBackground: Color(red: 0.1, green: 0.13, blue: 0.16),
        rowBorder: Color.white.opacity(0.18),
        panelBackground: Color(red: 0.03, green: 0.05, blue: 0.08),
        panelBorder: Color.white.opacity(0.2),
        topBarBackground: Color(red: 0.01, green: 0.03, blue: 0.06),
        topBarText: Color(red: 0.88, green: 0.96, blue: 1.0),
        nightIconActive: Color(red: 1.0, green: 0.87, blue: 0.45),
        labelText: Color.white.opacity(0.72),
        valueText: Color(red: 0.8, green: 0.95, blue: 1),
        separator: Color.white.opacity(0.16),
        activeRuleHighlight: Color(red: 0.15, green: 0.22, blue: 0.3),
        inactiveRuleText: Color.white.opacity(0.35)
      )
    }

    return NeoLCDTheme(
      windowBackground: Color(red: 0.94, green: 0.96, blue: 0.98),
      bezel: Color(red: 0.78, green: 0.82, blue: 0.88),
      rowBackground: Color(red: 0.9, green: 0.93, blue: 0.96),
      rowBorder: Color.black.opacity(0.12),
      panelBackground: Color(red: 0.82, green: 0.87, blue: 0.92),
      panelBorder: Color.black.opacity(0.18),
      topBarBackground: Color(red: 0.24, green: 0.32, blue: 0.4),
      topBarText: Color.white.opacity(0.92),
      nightIconActive: Color(red: 0.98, green: 0.76, blue: 0.1),
      labelText: Color.black.opacity(0.72),
      valueText: Color(red: 0.12, green: 0.28, blue: 0.4),
      separator: Color.black.opacity(0.12),
      activeRuleHighlight: Color(red: 0.82, green: 0.88, blue: 0.95),
      inactiveRuleText: Color.black.opacity(0.35)
    )
  }
}

// MARK: - Main Panel

struct DigitalFullMeterPanel: View {
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  let elapsed: TimeInterval
  let currentSpeedKph: Double
  let isNight: Bool
  let isWaiting: Bool
  let settings: MeterSettings
  let cityName: String
  let cityVehicleLabel: String
  let points: [TripPoint]
  let currentRoadName: String
  let topInset: CGFloat
  let fixedNow: Date?
  let surcharges: [FareSurcharge]?
  let currencyCode: String

  @State private var currentPage: NeoLCDPage = .fare
  @State private var liveNow: Date = Date()

  init(
    tripState: TripMeterState,
    fare: Double,
    waitingDuration: TimeInterval = 0,
    distanceMeters: Double = 0,
    elapsed: TimeInterval = 0,
    currentSpeedKph: Double = 0,
    isNight: Bool = false,
    isWaiting: Bool = false,
    settings: MeterSettings = .bengaluruDefault,
    cityName: String = FareCatalog.defaultProfile.name,
    cityVehicleLabel: String = "",
    points: [TripPoint] = [],
    currentRoadName: String = "",
    topInset: CGFloat = 0,
    fixedNow: Date? = nil,
    surcharges: [FareSurcharge]? = nil,
    currencyCode: String = "INR"
  ) {
    self.tripState = tripState
    self.fare = fare
    self.waitingDuration = waitingDuration
    self.distanceMeters = distanceMeters
    self.elapsed = elapsed
    self.currentSpeedKph = currentSpeedKph
    self.isNight = isNight
    self.isWaiting = isWaiting
    self.settings = settings
    self.cityName = cityName
    self.cityVehicleLabel = cityVehicleLabel
    self.points = points
    self.currentRoadName = currentRoadName
    self.topInset = topInset
    self.fixedNow = fixedNow
    self.surcharges = surcharges
    self.currencyCode = currencyCode
  }

  private var lockedPage: NeoLCDPage? {
    if tripState == .forHire {
      return .fareCard
    }
    if tripState == .complete || isWaiting {
      return .fare
    }
    return nil
  }

  private var shouldAutoRotate: Bool {
    lockedPage == nil && !TestEnvironment.isRunningTests
  }

  private var displayDate: Date {
    fixedNow ?? liveNow
  }

  private var timeText: String {
    Self.timeFormatter.string(from: displayDate)
  }

  private var compassText: String {
    CompassDirectionFormatter.direction(for: points)
  }

  var body: some View {
    MeterShell(style: .digital, topInset: topInset) { bodyWidth, bodyHeight in
      let faceWidth = bodyWidth * 0.93
      let faceHeight = bodyHeight * 0.9
      NeoLCDDisplayWindow(
        page: currentPage,
        tripState: tripState,
        fare: fare,
        waitingDuration: waitingDuration,
        distanceMeters: distanceMeters,
        elapsed: elapsed,
        currentSpeedKph: currentSpeedKph,
        isNight: isNight,
        isWaiting: isWaiting,
        settings: settings,
        cityName: cityName,
        cityVehicleLabel: cityVehicleLabel,
        timeText: timeText,
        compassText: compassText,
        currentRoadName: currentRoadName,
        width: faceWidth,
        height: faceHeight,
        surcharges: surcharges,
        currencyCode: currencyCode
      )
    }
    .onAppear {
      currentPage = lockedPage ?? .fare
      liveNow = Date()
    }
    .onChange(of: lockedPage) { _, page in
      if let page {
        currentPage = page
      } else {
        currentPage = .fare
      }
    }
    .task(id: shouldAutoRotate) {
      await autoRotatePages()
    }
    .task(id: fixedNow == nil) {
      guard fixedNow == nil else { return }
      while !Task.isCancelled {
        liveNow = Date()
        try? await Task.sleep(for: .seconds(30))
      }
    }
  }

  private func autoRotatePages() async {
    guard shouldAutoRotate else { return }

    while !Task.isCancelled {
      try? await Task.sleep(for: .seconds(8))
      guard !Task.isCancelled else { return }
      guard shouldAutoRotate else { return }
      advancePage()
    }
  }

  private func advancePage() {
    guard let currentIndex = NeoLCDPage.allCases.firstIndex(of: currentPage) else {
      currentPage = .fare
      return
    }
    let nextIndex = (currentIndex + 1) % NeoLCDPage.allCases.count
    currentPage = NeoLCDPage.allCases[nextIndex]
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.dateFormat = "hh:mm a"
    return formatter
  }()
}

// MARK: - Display Window

private struct NeoLCDDisplayWindow: View {
  @Environment(\.colorScheme) private var colorScheme

  let page: NeoLCDPage
  let tripState: TripMeterState
  let fare: Double
  let waitingDuration: TimeInterval
  let distanceMeters: Double
  let elapsed: TimeInterval
  let currentSpeedKph: Double
  let isNight: Bool
  let isWaiting: Bool
  let settings: MeterSettings
  let cityName: String
  let cityVehicleLabel: String
  let timeText: String
  let compassText: String
  let currentRoadName: String
  let width: CGFloat
  let height: CGFloat
  var surcharges: [FareSurcharge]? = nil
  var currencyCode: String = "INR"

  private var theme: NeoLCDTheme {
    .palette(for: colorScheme)
  }

  private var distanceKm: Double {
    distanceMeters / 1000
  }

  private var averageSpeedKph: Double {
    guard elapsed > 0 else { return 0 }
    let hours = elapsed / 3600
    guard hours > 0 else { return 0 }
    return distanceKm / hours
  }

  private var tripStatusText: String {
    if isWaiting {
      return "WAITING"
    }
    switch tripState {
    case .forHire:
      return "FOR HIRE"
    case .inProgress:
      return "HIRED"
    case .complete:
      return "STOPPED"
    }
  }

  private var evaluatedRules: [EvaluatedFareRule] {
    let profile = CityFareProfile(
      id: "display",
      cityId: "",
      name: cityName,
      vehicleType: "",
      cityKey: CityKey(city: cityName, region: nil, countryCode: currencyCode == "INR" ? "IN" : "US", currencyCode: currencyCode),
      rates: FareRates(settings: settings),
      multipliers: FareMultipliers(settings: settings),
      nightWindow: NightFareWindow(settings: settings),
      waitCharges: WaitingChargePolicy(settings: settings),
      surcharges: surcharges,
      effectiveFrom: Date()
    )
    let context = FareRuleContext(
      tripState: tripState,
      distanceKm: distanceKm,
      elapsedTime: elapsed,
      waitingTime: waitingDuration,
      currentSpeedKph: currentSpeedKph,
      tripDate: Date(),
      currentFare: fare
    )
    return FareRuleEvaluator.evaluate(profile: profile, context: context)
  }

  private var fareCardTitle: String {
    "FARE RULES"
  }

  private var topBarStatusText: String {
    NeoLCDHeaderFormatter.topBarStatus(statusText: tripStatusText, cityVehicleLabel: cityVehicleLabel)
  }

  private var fareCardHeaderText: String {
    NeoLCDHeaderFormatter.fareCardHeader(cityName: cityName, cityVehicleLabel: cityVehicleLabel)
  }

  private var bottomStatusText: String {
    guard isWaiting else { return currentRoadName }
    let freeWait = settings.freeWaitMinutes.formatted(.number.precision(.fractionLength(0)))
    let interval = settings.waitIntervalMinutes.formatted(.number.precision(.fractionLength(0)))
    let charge = settings.waitIntervalCharge.formatted(.number.precision(.fractionLength(0)))
    return "Waiting rules: first \(freeWait) min free, then Rs \(charge) every \(interval) min"
  }

  var body: some View {
    let cornerRadius = width * 0.03
    let borderWidth = max(1, width * 0.004)
    let topBarHeight = height * 0.06
    let bottomBarHeight = height * 0.1
    let contentHeight = max(height - topBarHeight - bottomBarHeight, 0)

    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(theme.windowBackground)
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(theme.bezel, lineWidth: borderWidth)
      )
      .overlay {
        VStack(spacing: 0) {
          NeoLCDTopBar(
            timeText: timeText,
            compassText: compassText,
            statusText: topBarStatusText,
            isNight: isNight,
            theme: theme
          )
            .frame(height: topBarHeight)

          Rectangle()
            .fill(theme.separator)
            .frame(height: borderWidth)

          pageContent
            .frame(height: contentHeight)
            .clipped()

          Rectangle()
            .fill(theme.separator)
            .frame(height: borderWidth)

          NeoLCDBottomRoadBar(text: bottomStatusText, theme: theme)
            .frame(height: bottomBarHeight)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      }
      .frame(width: width, height: height)
  }

  @ViewBuilder
  private var pageContent: some View {
    switch page {
    case .fare:
      NeoLCDTripOverviewPage(
        tripState: tripState,
        fare: fare,
        elapsed: elapsed,
        waitingDuration: waitingDuration,
        distanceKm: distanceKm,
        currentSpeedKph: currentSpeedKph,
        averageSpeedKph: averageSpeedKph,
        theme: theme
      )
    case .fareCard:
      NeoLCDFareCardPage(title: fareCardTitle, headerText: fareCardHeaderText, rules: evaluatedRules, theme: theme)
    }
  }
}

// MARK: - Page Content

private struct NeoLCDTripOverviewPage: View {
  let tripState: TripMeterState
  let fare: Double
  let elapsed: TimeInterval
  let waitingDuration: TimeInterval
  let distanceKm: Double
  let currentSpeedKph: Double
  let averageSpeedKph: Double
  let theme: NeoLCDTheme

  private var fareValue: String {
    let amount = tripState == .forHire ? 0 : fare
    return amount.formatted(.number.precision(.fractionLength(2)))
  }

  private var distanceValue: String {
    let distance = tripState == .forHire ? 0 : distanceKm
    return distance.formatted(.number.precision(.fractionLength(1)))
  }

  private var timeValue: String {
    tripState == .forHire ? "--:--" : hhmm(elapsed)
  }

  private var waitValue: String {
    tripState == .forHire ? "--:--" : hhmm(waitingDuration)
  }

  private var speedValue: String {
    currentSpeedKph.formatted(.number.precision(.fractionLength(1)))
  }

  private var averageSpeedValue: String {
    averageSpeedKph.formatted(.number.precision(.fractionLength(1)))
  }

  var body: some View {
    GeometryReader { geo in
      let horizontalPadding: CGFloat = 8
      let verticalPadding: CGFloat = 8
      let rowSpacing: CGFloat = 6
      let rows = 3
      let totalSpacing = rowSpacing * CGFloat(rows - 1)
      let availableRowsHeight = max(geo.size.height - (verticalPadding * 2) - totalSpacing, 0)
      let rowHeight = availableRowsHeight / CGFloat(rows)

      VStack(spacing: rowSpacing) {
        NeoLCDDualPanelMetricRow(
          leftLabel: "Fare",
          leftValue: fareValue,
          leftSuffixUnit: "₹",
          rightLabel: "Distance",
          rightValue: distanceValue,
          rightSuffixUnit: "KM",
          theme: theme
        )
        .frame(height: rowHeight)

        NeoLCDDualPanelMetricRow(
          leftLabel: "Trip Time",
          leftValue: timeValue,
          leftSuffixUnit: "",
          rightLabel: "Wait Time",
          rightValue: waitValue,
          rightSuffixUnit: "",
          theme: theme
        )
        .frame(height: rowHeight)

        NeoLCDDualPanelMetricRow(
          leftLabel: "Speed",
          leftValue: speedValue,
          leftSuffixUnit: "KM/H",
          rightLabel: "Avg Speed",
          rightValue: averageSpeedValue,
          rightSuffixUnit: "KM/H",
          theme: theme
        )
        .frame(height: rowHeight)
      }
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .background(theme.rowBackground)
    }
  }

  private func hhmm(_ interval: TimeInterval) -> String {
    let totalMinutes = max(Int(interval / 60), 0)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return String(format: "%02d:%02d", hours, minutes)
  }
}

private struct NeoLCDFareCardPage: View {
  let title: String
  let headerText: String
  let rules: [EvaluatedFareRule]
  let theme: NeoLCDTheme

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(headerText)
        .font(.system(size: 16, weight: .bold, design: .default))
        .foregroundStyle(theme.valueText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .center)

      Text(title)
        .font(.system(size: 12, weight: .semibold, design: .default))
        .foregroundStyle(theme.labelText)
        .lineLimit(1)
        .minimumScaleFactor(0.85)

      ForEach(rules) { evaluated in
        HStack(spacing: 6) {
          Circle()
            .fill(evaluated.isActive ? Color.green.opacity(0.8) : theme.inactiveRuleText.opacity(0.4))
            .frame(width: 6, height: 6)

          Text(evaluated.rule.description)
            .font(.system(size: 13, weight: evaluated.isActive ? .semibold : .regular, design: .default))
            .foregroundStyle(evaluated.isActive ? theme.valueText : theme.inactiveRuleText)
            .lineLimit(2)
            .minimumScaleFactor(0.85)

          Spacer(minLength: 0)

          if evaluated.isActive && evaluated.amount > 0 {
            Text(evaluated.amount.formatted(.number.precision(.fractionLength(evaluated.amount >= 100 ? 0 : 2))))
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .foregroundStyle(theme.valueText)
          }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(evaluated.isActive ? theme.activeRuleHighlight : Color.clear)
        )
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.rowBackground)
  }
}

// MARK: - Shared Rows

private struct NeoLCDDualPanelMetricRow: View {
  let leftLabel: String
  let leftValue: String
  let leftSuffixUnit: String
  let rightLabel: String
  let rightValue: String
  let rightSuffixUnit: String
  let theme: NeoLCDTheme

  var body: some View {
    GeometryReader { geo in
      let panelGap: CGFloat = 20
      let sideInset: CGFloat = 16
      let availableWidth = max(geo.size.width - (sideInset * 2) - panelGap, 0)
      let panelWidth = availableWidth / 2
      let labelHeight = geo.size.height * 0.36
      let panelAreaHeight = max(geo.size.height - labelHeight, 0)
      let panelHeight = panelAreaHeight * 0.74
      let valueFontSize = min(max(panelHeight * 0.54, 18), 40)

      HStack(spacing: panelGap) {
        metricPanel(
          label: leftLabel,
          value: leftValue,
          unit: leftSuffixUnit,
          panelWidth: panelWidth,
          labelHeight: labelHeight,
          panelAreaHeight: panelAreaHeight,
          panelHeight: panelHeight,
          valueFontSize: valueFontSize
        )

        metricPanel(
          label: rightLabel,
          value: rightValue,
          unit: rightSuffixUnit,
          panelWidth: panelWidth,
          labelHeight: labelHeight,
          panelAreaHeight: panelAreaHeight,
          panelHeight: panelHeight,
          valueFontSize: valueFontSize
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(.horizontal, 2)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(theme.rowBorder)
        .frame(height: 0.5)
    }
  }

  @ViewBuilder
  private func metricPanel(
    label: String,
    value: String,
    unit: String,
    panelWidth: CGFloat,
    labelHeight: CGFloat,
    panelAreaHeight: CGFloat,
    panelHeight: CGFloat,
    valueFontSize: CGFloat
  ) -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 6) {
        Text(label)
          .font(.system(size: 12, weight: .semibold, design: .default))
          .foregroundStyle(theme.labelText)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 6)
        Text(unit)
          .font(.system(size: 11, weight: .semibold, design: .default))
          .foregroundStyle(theme.labelText)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .opacity(unit.isEmpty ? 0 : 1)
      }
      .frame(height: labelHeight, alignment: .bottom)

      NeoLCDValuePanel(text: value, fontSize: valueFontSize, theme: theme)
        .frame(height: panelHeight)
        .frame(maxHeight: panelAreaHeight, alignment: .center)
    }
    .frame(width: panelWidth)
    .frame(maxHeight: .infinity)
  }
}

private struct NeoLCDValuePanel: View {
  let text: String
  let fontSize: CGFloat
  let theme: NeoLCDTheme

  var body: some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .fill(theme.panelBackground)
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(theme.panelBorder, lineWidth: 1)
      )
      .overlay {
        Text(text)
          .font(.system(size: fontSize, weight: .semibold, design: .default))
          .monospacedDigit()
          .foregroundStyle(theme.valueText)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .padding(.horizontal, 8)
      }
  }
}

// MARK: - Fixed Bars

private struct NeoLCDTopBar: View {
  let timeText: String
  let compassText: String
  let statusText: String
  let isNight: Bool
  let theme: NeoLCDTheme

  var body: some View {
    ZStack {
      HStack {
        HStack(spacing: 4) {
          Text(timeText)
            .font(.system(size: 10, weight: .bold, design: .default))
            .foregroundStyle(theme.topBarText)
          if isNight {
            Image(systemName: "moon.fill")
              .font(.system(size: 9, weight: .semibold))
              .foregroundStyle(theme.nightIconActive)
          }
        }
        Spacer()
        Text(compassText)
          .font(.system(size: 10, weight: .bold, design: .default))
          .foregroundStyle(theme.topBarText)
      }

      Text(statusText)
        .font(.system(size: 10, weight: .semibold, design: .default))
        .foregroundStyle(theme.topBarText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.topBarBackground)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(theme.separator)
        .frame(height: 1)
    }
  }
}

private struct NeoLCDBottomRoadBar: View {
  let text: String
  let theme: NeoLCDTheme

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold, design: .default))
      .foregroundStyle(theme.topBarText)
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .background(theme.topBarBackground)
  }
}

// MARK: - Helpers

// NeoLCDFareRuleBuilder — replaced by FareRuleEvaluator

enum NeoLCDHeaderFormatter {
  static func topBarStatus(statusText: String, cityVehicleLabel: String) -> String {
    let context = cityVehicleLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !context.isEmpty else { return statusText }
    return "\(statusText) · \(context)"
  }

  static func fareCardHeader(cityName: String, cityVehicleLabel: String) -> String {
    let context = cityVehicleLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !context.isEmpty else { return cityName }
    return context
  }
}

enum CompassDirectionFormatter {
  static func direction(for points: [TripPoint]) -> String {
    guard points.count >= 2 else { return "--" }

    var index = points.count - 1
    while index > 0 {
      let newer = points[index].coordinate
      let older = points[index - 1].coordinate
      if let heading = bearing(from: older, to: newer) {
        return cardinalDirection(for: heading)
      }
      index -= 1
    }

    return "--"
  }

  private static func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double? {
    let startLat = start.latitude * .pi / 180
    let startLon = start.longitude * .pi / 180
    let endLat = end.latitude * .pi / 180
    let endLon = end.longitude * .pi / 180

    let deltaLon = endLon - startLon
    let y = sin(deltaLon) * cos(endLat)
    let x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(deltaLon)
    guard !(abs(x) < 0.000001 && abs(y) < 0.000001) else { return nil }

    let radians = atan2(y, x)
    let degrees = radians * 180 / .pi
    return (degrees + 360).truncatingRemainder(dividingBy: 360)
  }

  private static func cardinalDirection(for heading: Double) -> String {
    let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
    let index = Int((heading + 22.5) / 45.0)
    return directions[min(max(index, 0), directions.count - 1)]
  }
}

// MARK: - Display Mode Wrapper

struct DigitalDisplayPanel: View {
  let tripState: TripMeterState
  let fare: Double

  var body: some View {
    DigitalFullMeterPanel(tripState: tripState, fare: fare)
  }
}
