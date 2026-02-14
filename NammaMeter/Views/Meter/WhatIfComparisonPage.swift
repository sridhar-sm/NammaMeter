import SwiftUI

struct WhatIfComparisonPage: View {
  let result: WhatIfResult
  let primaryFare: Double
  let primaryCurrencyCode: String

  @Environment(ExchangeRateProvider.self) private var exchangeRateProvider
  @State private var showNativeCurrency = false

  var body: some View {
    GeometryReader { geo in
      let horizontalPadding: CGFloat = 12
      let availableWidth = max(geo.size.width - (horizontalPadding * 2), 0)

      VStack(spacing: 12) {
        VStack(spacing: 2) {
          Text(result.cityName)
            .font(FontPresets.Display.small)
            .lineLimit(1)
          Text(VehicleTypeCatalog.displayName(for: result.vehicleType))
            .font(FontPresets.Body.mini)
            .lineLimit(1)
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(Theme.ink)

        FareInfoTile(
          valueText: formattedFare,
          labelText: fareLabelText,
          size: CGSize(width: availableWidth, height: 56),
          showsChevron: isForeignCurrency,
          isExpanded: showNativeCurrency
        )
        .onTapGesture {
          guard isForeignCurrency else { return }
          showNativeCurrency.toggle()
        }

        differenceView(width: availableWidth)

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, 12)
    }
  }

  private var isForeignCurrency: Bool {
    result.currencyCode != primaryCurrencyCode
  }

  private var formattedFare: String {
    if showNativeCurrency || !isForeignCurrency {
      return formatCurrency(result.fareInNativeCurrency, code: result.currencyCode)
    }
    let converted = convertToPrimary(result.fareInNativeCurrency)
    return formatCurrency(converted, code: primaryCurrencyCode)
  }

  private var fareLabelText: String {
    if showNativeCurrency {
      return "WhatIf Fare (\(result.currencyCode))"
    }
    return "WhatIf Fare"
  }

  private func differenceView(width: CGFloat) -> some View {
    let whatIfInPrimary = isForeignCurrency
      ? convertToPrimary(result.fareInNativeCurrency)
      : result.fareInNativeCurrency
    let diff = whatIfInPrimary - primaryFare
    let sign = diff >= 0 ? "+" : ""
    let formatted = formatCurrency(abs(diff), code: primaryCurrencyCode)

    return FareInfoTile(
      valueText: "\(sign)\(formatted)",
      labelText: "vs Your Fare",
      size: CGSize(width: width, height: 44),
      showsChevron: false,
      isExpanded: false
    )
  }

  private func convertToPrimary(_ amount: Double) -> Double {
    exchangeRateProvider.convert(amount, from: result.currencyCode, to: primaryCurrencyCode) ?? amount
  }

}
