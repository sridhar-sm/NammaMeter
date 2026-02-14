import Foundation

struct CityKey: Hashable, Sendable {
  var city: String
  var region: String?
  var countryCode: String
  var currencyCode: String
}

extension CityKey: Codable {
  enum CodingKeys: String, CodingKey {
    case city, region, countryCode, currencyCode
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    city = try container.decode(String.self, forKey: .city)
    region = try container.decodeIfPresent(String.self, forKey: .region)
    countryCode = try container.decode(String.self, forKey: .countryCode)
    currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "INR"
  }
}

struct FareRates: Equatable, Sendable {
  var baseFare: Double
  var perKmRate: Double
  var perMinuteRate: Double
  var includedKm: Double
  var minFare: Double
  var perMinuteWhenSlow: Double?
  var slowSpeedThresholdKph: Double?
}

extension FareRates: Codable {
  enum CodingKeys: String, CodingKey {
    case baseFare, perKmRate, perMinuteRate, includedKm, minFare
    case perMinuteWhenSlow, slowSpeedThresholdKph
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseFare = try container.decode(Double.self, forKey: .baseFare)
    perKmRate = try container.decode(Double.self, forKey: .perKmRate)
    perMinuteRate = try container.decode(Double.self, forKey: .perMinuteRate)
    includedKm = try container.decode(Double.self, forKey: .includedKm)
    minFare = try container.decode(Double.self, forKey: .minFare)
    perMinuteWhenSlow = try container.decodeIfPresent(Double.self, forKey: .perMinuteWhenSlow)
    slowSpeedThresholdKph = try container.decodeIfPresent(Double.self, forKey: .slowSpeedThresholdKph)
  }
}

struct FareMultipliers: Codable, Equatable, Sendable {
  var night: Double
}

struct NightFareWindow: Codable, Equatable, Sendable {
  var startHour: Int
  var endHour: Int
}

extension NightFareWindow {
  static let defaultWindow = NightFareWindow(startHour: 22, endHour: 5)
}

struct WaitingChargePolicy: Codable, Equatable, Sendable {
  var freeWaitMinutes: Double
  var waitIntervalMinutes: Double
  var waitIntervalCharge: Double
}

struct FlatRateFare: Codable, Identifiable, Equatable, Sendable {
  var id: String
  var routeName: String
  var fare: Double
  var currencyCode: String
}

struct CityFareProfile: Codable, Identifiable, Equatable, Sendable {
  var id: String
  var cityId: String
  var name: String
  var vehicleType: String
  var cityKey: CityKey
  var rates: FareRates
  var multipliers: FareMultipliers
  var nightWindow: NightFareWindow
  var waitCharges: WaitingChargePolicy
  var surcharges: [FareSurcharge]?
  var flatRates: [FlatRateFare]?
  var effectiveFrom: Date
}

extension CityFareProfile {
  enum CodingKeys: String, CodingKey {
    case id
    case cityId
    case name
    case vehicleType
    case cityKey
    case rates
    case multipliers
    case nightWindow
    case waitCharges
    case surcharges
    case flatRates
    case effectiveFrom
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    cityId = try container.decode(String.self, forKey: .cityId)
    name = try container.decode(String.self, forKey: .name)
    vehicleType = try container.decodeIfPresent(String.self, forKey: .vehicleType)
      ?? VehicleTypeCatalog.autoRickshaw
    cityKey = try container.decode(CityKey.self, forKey: .cityKey)
    rates = try container.decode(FareRates.self, forKey: .rates)
    multipliers = try container.decode(FareMultipliers.self, forKey: .multipliers)
    nightWindow = try container.decodeIfPresent(NightFareWindow.self, forKey: .nightWindow)
      ?? NightFareWindow.defaultWindow
    waitCharges = try container.decode(WaitingChargePolicy.self, forKey: .waitCharges)
    surcharges = try container.decodeIfPresent([FareSurcharge].self, forKey: .surcharges)
    flatRates = try container.decodeIfPresent([FlatRateFare].self, forKey: .flatRates)
    effectiveFrom = try container.decode(Date.self, forKey: .effectiveFrom)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(cityId, forKey: .cityId)
    try container.encode(name, forKey: .name)
    try container.encode(vehicleType, forKey: .vehicleType)
    try container.encode(cityKey, forKey: .cityKey)
    try container.encode(rates, forKey: .rates)
    try container.encode(multipliers, forKey: .multipliers)
    try container.encode(nightWindow, forKey: .nightWindow)
    try container.encode(waitCharges, forKey: .waitCharges)
    try container.encodeIfPresent(surcharges, forKey: .surcharges)
    try container.encodeIfPresent(flatRates, forKey: .flatRates)
    try container.encode(effectiveFrom, forKey: .effectiveFrom)
  }
}

struct FareProfileSettings: Codable, Sendable {
  static let currentSchemaVersion = 3

  var schemaVersion: Int
  var selectedCityId: String?
  var profiles: [CityFareProfile]
  var catalogVersionApplied: Int
  var whatIfFavorites: [WhatIfFavorite]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case selectedCityId
    case profiles
    case catalogVersionApplied
    case whatIfFavorites
  }

  init(schemaVersion: Int, selectedCityId: String?, profiles: [CityFareProfile], catalogVersionApplied: Int, whatIfFavorites: [WhatIfFavorite] = []) {
    self.schemaVersion = schemaVersion
    self.selectedCityId = selectedCityId
    self.profiles = profiles
    self.catalogVersionApplied = catalogVersionApplied
    self.whatIfFavorites = whatIfFavorites
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? FareProfileSettings.currentSchemaVersion
    selectedCityId = try container.decodeIfPresent(String.self, forKey: .selectedCityId)
    profiles = try container.decodeIfPresent([CityFareProfile].self, forKey: .profiles) ?? []
    catalogVersionApplied = try container.decodeIfPresent(Int.self, forKey: .catalogVersionApplied) ?? 0
    whatIfFavorites = try container.decodeIfPresent([WhatIfFavorite].self, forKey: .whatIfFavorites) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    try container.encode(selectedCityId, forKey: .selectedCityId)
    try container.encode(profiles, forKey: .profiles)
    try container.encode(catalogVersionApplied, forKey: .catalogVersionApplied)
    try container.encode(whatIfFavorites, forKey: .whatIfFavorites)
  }
}

struct WhatIfFavorite: Codable, Identifiable, Equatable, Sendable {
  var cityId: String
  var vehicleType: String

  var id: String { "\(cityId):\(vehicleType)" }
}

struct FareCatalogEntry {
  let introducedInVersion: Int
  let profile: CityFareProfile
}

enum FareCatalog {
  static let currentVersion = 2
  static let defaultCityId = "bengaluru"

  static let entries: [FareCatalogEntry] = [
    FareCatalogEntry(
      introducedInVersion: 2,
      profile: CityFareProfile(
        id: "bengaluru-20250801",
        cityId: defaultCityId,
        name: "Bengaluru",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Bengaluru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(
          baseFare: 36,
          perKmRate: 18,
          perMinuteRate: 0,
          includedKm: 2.0,
          minFare: 36
        ),
        multipliers: FareMultipliers(night: 1.5),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(
          freeWaitMinutes: 5,
          waitIntervalMinutes: 15,
          waitIntervalCharge: 10
        ),
        surcharges: [
          FareSurcharge(
            id: "bengaluru-night",
            name: "Night",
            type: .percentageOfFare(0.50),
            conditions: [.timeOfDay(start: 22, end: 5)]
          ),
        ],
        effectiveFrom: startOfDay(year: 2025, month: 8, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 2,
      profile: CityFareProfile(
        id: "mandya-20260124",
        cityId: "mandya",
        name: "Mandya",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Mandya", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(
          baseFare: 30,
          perKmRate: 15,
          perMinuteRate: 0,
          includedKm: 1.9,
          minFare: 30
        ),
        multipliers: FareMultipliers(night: 1.5),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(
          freeWaitMinutes: 5,
          waitIntervalMinutes: 15,
          waitIntervalCharge: 5
        ),
        surcharges: [
          FareSurcharge(
            id: "mandya-night",
            name: "Night",
            type: .percentageOfFare(0.50),
            conditions: [.timeOfDay(start: 22, end: 5)]
          ),
        ],
        effectiveFrom: startOfDay(year: 2026, month: 1, day: 24)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 2,
      profile: CityFareProfile(
        id: "mysuru-20260101",
        cityId: "mysuru",
        name: "Mysuru",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Mysuru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(
          baseFare: 36,
          perKmRate: 18,
          perMinuteRate: 0,
          includedKm: 2.0,
          minFare: 36
        ),
        multipliers: FareMultipliers(night: 1.5),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(
          freeWaitMinutes: 5,
          waitIntervalMinutes: 15,
          waitIntervalCharge: 10
        ),
        surcharges: [
          FareSurcharge(
            id: "mysuru-night",
            name: "Night",
            type: .percentageOfFare(0.50),
            conditions: [.timeOfDay(start: 22, end: 5)]
          ),
        ],
        effectiveFrom: startOfDay(year: 2026, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 2,
      profile: CityFareProfile(
        id: "dakshina-kannada-20221201",
        cityId: "dakshina-kannada",
        name: "Dakshina Kannada",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Dakshina Kannada", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(
          baseFare: 35,
          perKmRate: 20,
          perMinuteRate: 0,
          includedKm: 1.5,
          minFare: 35
        ),
        multipliers: FareMultipliers(night: 1.5),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(
          freeWaitMinutes: 15,
          waitIntervalMinutes: 15,
          waitIntervalCharge: 5
        ),
        surcharges: [
          FareSurcharge(
            id: "dakshina-kannada-night",
            name: "Night",
            type: .percentageOfFare(0.50),
            conditions: [.timeOfDay(start: 22, end: 5)]
          ),
        ],
        effectiveFrom: startOfDay(year: 2022, month: 12, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 2,
      profile: CityFareProfile(
        id: "udupi-20221001",
        cityId: "udupi",
        name: "Udupi",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Udupi", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(
          baseFare: 40,
          perKmRate: 20,
          perMinuteRate: 0,
          includedKm: 1.5,
          minFare: 40
        ),
        multipliers: FareMultipliers(night: 1.5),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(
          freeWaitMinutes: 15,
          waitIntervalMinutes: 15,
          waitIntervalCharge: 5
        ),
        surcharges: [
          FareSurcharge(
            id: "udupi-night",
            name: "Night",
            type: .percentageOfFare(0.50),
            conditions: [.timeOfDay(start: 22, end: 5)]
          ),
        ],
        effectiveFrom: startOfDay(year: 2022, month: 10, day: 1)
      )
    )
  ]

  static var defaultProfile: CityFareProfile {
    entries.first(where: { $0.profile.cityId == defaultCityId })?.profile
      ?? entries[0].profile
  }

  static func startOfDay(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 0
    components.minute = 0
    components.second = 0
    return Calendar.current.date(from: components) ?? Date(timeIntervalSince1970: 0)
  }
}

extension FareRates {
  init(settings: MeterSettings) {
    baseFare = settings.baseFare
    perKmRate = settings.perKmRate
    perMinuteRate = settings.perMinuteRate
    includedKm = settings.includedKm
    minFare = settings.minFare
    perMinuteWhenSlow = nil
    slowSpeedThresholdKph = nil
  }
}

extension NightFareWindow {
  init(settings: MeterSettings) {
    startHour = settings.nightStartHour
    endHour = settings.nightEndHour
  }
}

extension WaitingChargePolicy {
  init(settings: MeterSettings) {
    freeWaitMinutes = settings.freeWaitMinutes
    waitIntervalMinutes = settings.waitIntervalMinutes
    waitIntervalCharge = settings.waitIntervalCharge
  }
}

extension FareMultipliers {
  init(settings: MeterSettings) {
    night = settings.nightMultiplier
  }
}

extension MeterSettings {
  init(profile: CityFareProfile) {
    self.init(
      baseFare: profile.rates.baseFare,
      perKmRate: profile.rates.perKmRate,
      perMinuteRate: profile.rates.perMinuteRate,
      includedKm: profile.rates.includedKm,
      minFare: profile.rates.minFare,
      nightMultiplier: profile.multipliers.night,
      nightStartHour: profile.nightWindow.startHour,
      nightEndHour: profile.nightWindow.endHour,
      freeWaitMinutes: profile.waitCharges.freeWaitMinutes,
      waitIntervalMinutes: profile.waitCharges.waitIntervalMinutes,
      waitIntervalCharge: profile.waitCharges.waitIntervalCharge,
      keepScreenAwakeDuringTrip: false
    )
  }
}
