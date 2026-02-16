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
  var selectedVehicleType: String?
  var profiles: [CityFareProfile]
  var catalogVersionApplied: Int
  var whatIfFavorites: [WhatIfFavorite]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case selectedCityId
    case selectedVehicleType
    case profiles
    case catalogVersionApplied
    case whatIfFavorites
  }

  init(schemaVersion: Int, selectedCityId: String?, profiles: [CityFareProfile], catalogVersionApplied: Int, selectedVehicleType: String? = nil, whatIfFavorites: [WhatIfFavorite] = []) {
    self.schemaVersion = schemaVersion
    self.selectedCityId = selectedCityId
    self.selectedVehicleType = selectedVehicleType
    self.profiles = profiles
    self.catalogVersionApplied = catalogVersionApplied
    self.whatIfFavorites = whatIfFavorites
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? FareProfileSettings.currentSchemaVersion
    selectedCityId = try container.decodeIfPresent(String.self, forKey: .selectedCityId)
    selectedVehicleType = try container.decodeIfPresent(String.self, forKey: .selectedVehicleType)
    profiles = try container.decodeIfPresent([CityFareProfile].self, forKey: .profiles) ?? []
    catalogVersionApplied = try container.decodeIfPresent(Int.self, forKey: .catalogVersionApplied) ?? 0
    whatIfFavorites = try container.decodeIfPresent([WhatIfFavorite].self, forKey: .whatIfFavorites) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    try container.encode(selectedCityId, forKey: .selectedCityId)
    try container.encodeIfPresent(selectedVehicleType, forKey: .selectedVehicleType)
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

struct CityGroup: Identifiable, Sendable {
  var cityId: String
  var name: String
  var cityKey: CityKey
  var vehicleTypes: [String]

  var id: String { cityId }
}

struct FareCatalogEntry {
  let introducedInVersion: Int
  let profile: CityFareProfile
}

enum FareCatalog {
  static let currentVersion = 3
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
    ),

    // MARK: - Version 3: Indian cities (new vehicle types)

    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "bengaluru-taxi-economy-20240601",
        cityId: "bengaluru",
        name: "Bengaluru",
        vehicleType: VehicleTypeCatalog.taxiEconomy,
        cityKey: CityKey(city: "Bengaluru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 100, perKmRate: 24, perMinuteRate: 0, includedKm: 4.0, minFare: 100),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2024, month: 6, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "bengaluru-taxi-midrange-20240601",
        cityId: "bengaluru",
        name: "Bengaluru",
        vehicleType: VehicleTypeCatalog.taxiMidrange,
        cityKey: CityKey(city: "Bengaluru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 115, perKmRate: 28, perMinuteRate: 0, includedKm: 4.0, minFare: 115),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2024, month: 6, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "bengaluru-taxi-premium-20240601",
        cityId: "bengaluru",
        name: "Bengaluru",
        vehicleType: VehicleTypeCatalog.taxiPremium,
        cityKey: CityKey(city: "Bengaluru", region: "Karnataka", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 130, perKmRate: 32, perMinuteRate: 0, includedKm: 4.0, minFare: 130),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2024, month: 6, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "delhi-auto-20230901",
        cityId: "delhi",
        name: "Delhi",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Delhi", region: "Delhi", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 25, perKmRate: 8, perMinuteRate: 0, includedKm: 2.0, minFare: 25),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 23, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 15, waitIntervalCharge: 7.5),
        surcharges: [
          FareSurcharge(id: "delhi-auto-night", name: "Night", type: .percentageOfFare(0.25),
                        conditions: [.timeOfDay(start: 23, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 9, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "delhi-taxi-nonac-20230901",
        cityId: "delhi",
        name: "Delhi",
        vehicleType: VehicleTypeCatalog.taxiNonAC,
        cityKey: CityKey(city: "Delhi", region: "Delhi", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 25, perKmRate: 14, perMinuteRate: 0, includedKm: 1.0, minFare: 25),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 23, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 15, waitIntervalCharge: 7.5),
        surcharges: [
          FareSurcharge(id: "delhi-taxi-nonac-night", name: "Night", type: .percentageOfFare(0.25),
                        conditions: [.timeOfDay(start: 23, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 9, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "delhi-taxi-ac-20230901",
        cityId: "delhi",
        name: "Delhi",
        vehicleType: VehicleTypeCatalog.taxiAC,
        cityKey: CityKey(city: "Delhi", region: "Delhi", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 25, perKmRate: 16, perMinuteRate: 0, includedKm: 1.0, minFare: 25),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 23, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 15, waitIntervalCharge: 7.5),
        surcharges: [
          FareSurcharge(id: "delhi-taxi-ac-night", name: "Night", type: .percentageOfFare(0.25),
                        conditions: [.timeOfDay(start: 23, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 9, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "hyderabad-auto-20221001",
        cityId: "hyderabad",
        name: "Hyderabad",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Hyderabad", region: "Telangana", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 30, perKmRate: 15, perMinuteRate: 0, includedKm: 1.5, minFare: 30),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 0, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        surcharges: [
          FareSurcharge(id: "hyderabad-auto-night", name: "Night", type: .percentageOfFare(0.50),
                        conditions: [.timeOfDay(start: 0, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2022, month: 10, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "hyderabad-citytaxi-20221001",
        cityId: "hyderabad",
        name: "Hyderabad",
        vehicleType: VehicleTypeCatalog.cityTaxi,
        cityKey: CityKey(city: "Hyderabad", region: "Telangana", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 100, perKmRate: 21, perMinuteRate: 0, includedKm: 4.0, minFare: 100),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 0, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        surcharges: [
          FareSurcharge(id: "hyderabad-citytaxi-night", name: "Night", type: .percentageOfFare(0.50),
                        conditions: [.timeOfDay(start: 0, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2022, month: 10, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "chennai-auto-20230601",
        cityId: "chennai",
        name: "Chennai",
        vehicleType: VehicleTypeCatalog.autoRickshaw,
        cityKey: CityKey(city: "Chennai", region: "Tamil Nadu", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 25, perKmRate: 12, perMinuteRate: 0, includedKm: 1.8, minFare: 25),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 22, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        surcharges: [
          FareSurcharge(id: "chennai-auto-night", name: "Night", type: .percentageOfFare(0.50),
                        conditions: [.timeOfDay(start: 22, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 6, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "chennai-taxi-20230601",
        cityId: "chennai",
        name: "Chennai",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Chennai", region: "Tamil Nadu", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 100, perKmRate: 24, perMinuteRate: 0, includedKm: 4.0, minFare: 100),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2023, month: 6, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "kolkata-yellowtaxi-20230101",
        cityId: "kolkata",
        name: "Kolkata",
        vehicleType: VehicleTypeCatalog.yellowTaxi,
        cityKey: CityKey(city: "Kolkata", region: "West Bengal", countryCode: "IN", currencyCode: "INR"),
        rates: FareRates(baseFare: 30, perKmRate: 15, perMinuteRate: 0, includedKm: 2.0, minFare: 30),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow(startHour: 23, endHour: 5),
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        surcharges: [
          FareSurcharge(id: "kolkata-yellowtaxi-night", name: "Night", type: .percentageOfFare(0.25),
                        conditions: [.timeOfDay(start: 23, end: 5)]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),

    // MARK: - Version 3: US cities

    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "nyc-yellowtaxi-20230101",
        cityId: "nyc",
        name: "New York City",
        vehicleType: VehicleTypeCatalog.yellowTaxi,
        cityKey: CityKey(city: "New York City", region: "New York", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(
          baseFare: 3.00, perKmRate: 2.18, perMinuteRate: 0, includedKm: 0, minFare: 3.00,
          perMinuteWhenSlow: 0.70, slowSpeedThresholdKph: 19
        ),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        surcharges: [
          FareSurcharge(id: "nyc-night", name: "Night", type: .fixedAmount(1.00),
                        conditions: [.timeOfDay(start: 20, end: 6)]),
          FareSurcharge(id: "nyc-rush", name: "Rush Hour", type: .fixedAmount(2.50),
                        conditions: [.weekdays(start: 16, end: 20)]),
          FareSurcharge(id: "nyc-mta", name: "MTA Tax", type: .fixedAmount(0.50),
                        conditions: [.always]),
          FareSurcharge(id: "nyc-improvement", name: "Improvement", type: .fixedAmount(1.00),
                        conditions: [.always]),
        ],
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "seattle-taxi-20230101",
        cityId: "seattle",
        name: "Seattle",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Seattle", region: "Washington", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(baseFare: 2.60, perKmRate: 1.68, perMinuteRate: 0, includedKm: 0.18, minFare: 2.60),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 15, waitIntervalCharge: 7.50),
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "chicago-taxi-20230101",
        cityId: "chicago",
        name: "Chicago",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Chicago", region: "Illinois", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(
          baseFare: 3.25, perKmRate: 1.40, perMinuteRate: 0, includedKm: 0, minFare: 3.25,
          perMinuteWhenSlow: 0.42, slowSpeedThresholdKph: 18
        ),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "dallas-taxi-20230101",
        cityId: "dallas",
        name: "Dallas",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Dallas", region: "Texas", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(
          baseFare: 3.00, perKmRate: 1.74, perMinuteRate: 0, includedKm: 0, minFare: 3.00,
          perMinuteWhenSlow: 0.40, slowSpeedThresholdKph: 14
        ),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "philadelphia-taxi-20230101",
        cityId: "philadelphia",
        name: "Philadelphia",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Philadelphia", region: "Pennsylvania", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(
          baseFare: 2.70, perKmRate: 1.86, perMinuteRate: 0, includedKm: 0, minFare: 2.70,
          perMinuteWhenSlow: 0.48, slowSpeedThresholdKph: 15
        ),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
    FareCatalogEntry(
      introducedInVersion: 3,
      profile: CityFareProfile(
        id: "la-taxi-20230101",
        cityId: "la",
        name: "Los Angeles",
        vehicleType: VehicleTypeCatalog.taxi,
        cityKey: CityKey(city: "Los Angeles", region: "California", countryCode: "US", currencyCode: "USD"),
        rates: FareRates(
          baseFare: 3.10, perKmRate: 1.85, perMinuteRate: 0, includedKm: 0, minFare: 3.10,
          perMinuteWhenSlow: 0.54, slowSpeedThresholdKph: 17
        ),
        multipliers: FareMultipliers(night: 1.0),
        nightWindow: NightFareWindow.defaultWindow,
        waitCharges: WaitingChargePolicy(freeWaitMinutes: 0, waitIntervalMinutes: 0, waitIntervalCharge: 0),
        effectiveFrom: startOfDay(year: 2023, month: 1, day: 1)
      )
    ),
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
