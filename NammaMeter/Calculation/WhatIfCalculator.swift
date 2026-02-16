import Foundation

struct WhatIfResult: Equatable, Sendable {
  let favorite: WhatIfFavorite
  let cityName: String
  let vehicleType: String
  let currencyCode: String
  let fareInNativeCurrency: Double
  let fareBreakdown: FareBreakdown
}

enum WhatIfCalculator {
  static func calculate(
    favorite: WhatIfFavorite,
    profile: CityFareProfile,
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    tripDate: Date,
    isNight: Bool
  ) -> WhatIfResult {
    let settings = MeterSettings(profile: profile)
    let calculator = FareCalculator(
      settings: settings,
      perMinuteWhenSlow: profile.rates.perMinuteWhenSlow,
      slowSpeedThresholdKph: profile.rates.slowSpeedThresholdKph
    )

    // WhatIf uses nil speed — for speed-based cities this means
    // max(distanceFare, timeFare) over the full trip duration
    let breakdown = calculator.calculateFare(
      distanceKm: distanceKm,
      elapsedTime: elapsedTime,
      waitingTime: waitingTime,
      currentSpeedKph: nil,
      surcharges: profile.surcharges,
      tripDate: tripDate,
      isNight: isNight
    )

    return WhatIfResult(
      favorite: favorite,
      cityName: profile.name,
      vehicleType: profile.vehicleType,
      currencyCode: profile.cityKey.currencyCode,
      fareInNativeCurrency: breakdown.total,
      fareBreakdown: breakdown
    )
  }

  static func calculateAll(
    favorites: [WhatIfFavorite],
    profileLookup: (WhatIfFavorite) -> CityFareProfile?,
    distanceKm: Double,
    elapsedTime: TimeInterval,
    waitingTime: TimeInterval,
    tripDate: Date,
    isNight: Bool
  ) -> [WhatIfResult] {
    favorites.compactMap { favorite in
      guard let profile = profileLookup(favorite) else { return nil }
      return calculate(
        favorite: favorite,
        profile: profile,
        distanceKm: distanceKm,
        elapsedTime: elapsedTime,
        waitingTime: waitingTime,
        tripDate: tripDate,
        isNight: isNight
      )
    }
  }
}
