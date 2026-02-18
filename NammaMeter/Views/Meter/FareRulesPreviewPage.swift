import SwiftUI

struct FareRulesPreviewPage: View {
  let profile: CityFareProfile

  var body: some View {
    GeometryReader { geo in
      let horizontalPadding: CGFloat = 12

      VStack(spacing: 12) {
        VStack(spacing: 2) {
          Text(profile.name)
            .font(FontPresets.Display.small)
            .lineLimit(1)
          Text(VehicleTypeCatalog.displayName(for: profile.vehicleType))
            .font(FontPresets.Body.mini)
            .lineLimit(1)
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(Theme.ink)

        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(rules) { rule in
              fareRuleRow(rule)
            }
          }
        }

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, 12)
    }
  }

  private var rules: [FareRule] {
    FareRuleEvaluator.allRules(from: profile)
  }

  private func fareRuleRow(_ rule: FareRule) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(rule.label)
        .font(FontPresets.Display.caption)
        .foregroundStyle(Theme.ink)
      Text(rule.description)
        .font(FontPresets.Body.small)
        .foregroundStyle(Theme.ink.opacity(0.7))
        .lineLimit(2)
        .minimumScaleFactor(0.85)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Theme.mango.opacity(0.3))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
