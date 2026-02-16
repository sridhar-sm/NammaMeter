import Foundation

struct VehicleTypeInfo: Sendable {
  let id: String
  let displayName: String
  let symbolName: String
}

enum VehicleTypeCatalog {
  static let autoRickshaw = "auto-rickshaw"
  static let taxi = "taxi"
  static let taxiAC = "taxi-ac"
  static let taxiNonAC = "taxi-nonac"
  static let taxiEconomy = "taxi-economy"
  static let taxiMidrange = "taxi-midrange"
  static let taxiPremium = "taxi-premium"
  static let cityTaxi = "city-taxi"
  static let yellowTaxi = "yellow-taxi"
  static let cab = "cab"
  static let tuktuk = "tuktuk"

  static let allTypes: [String] = [
    autoRickshaw, taxi, taxiNonAC, taxiAC, taxiEconomy,
    taxiMidrange, taxiPremium, cityTaxi, yellowTaxi, cab, tuktuk,
  ]

  private static let knownTypes: [String: VehicleTypeInfo] = [
    autoRickshaw: VehicleTypeInfo(id: autoRickshaw, displayName: "Auto Rickshaw", symbolName: "car.side"),
    taxi: VehicleTypeInfo(id: taxi, displayName: "Taxi", symbolName: "car"),
    taxiAC: VehicleTypeInfo(id: taxiAC, displayName: "Taxi (AC)", symbolName: "car"),
    taxiNonAC: VehicleTypeInfo(id: taxiNonAC, displayName: "Taxi (Non-AC)", symbolName: "car"),
    taxiEconomy: VehicleTypeInfo(id: taxiEconomy, displayName: "Taxi (Economy)", symbolName: "car"),
    taxiMidrange: VehicleTypeInfo(id: taxiMidrange, displayName: "Taxi (Mid-range)", symbolName: "car"),
    taxiPremium: VehicleTypeInfo(id: taxiPremium, displayName: "Taxi (Premium)", symbolName: "car"),
    cityTaxi: VehicleTypeInfo(id: cityTaxi, displayName: "City Taxi", symbolName: "car"),
    yellowTaxi: VehicleTypeInfo(id: yellowTaxi, displayName: "Yellow Taxi", symbolName: "car"),
    cab: VehicleTypeInfo(id: cab, displayName: "Cab", symbolName: "car"),
    tuktuk: VehicleTypeInfo(id: tuktuk, displayName: "Tuk-Tuk", symbolName: "car.side"),
  ]

  static func displayName(for vehicleType: String) -> String {
    knownTypes[vehicleType]?.displayName ?? vehicleType.capitalized
  }

  static func symbol(for vehicleType: String) -> String {
    knownTypes[vehicleType]?.symbolName ?? "car"
  }

  static func info(for vehicleType: String) -> VehicleTypeInfo {
    knownTypes[vehicleType] ?? VehicleTypeInfo(id: vehicleType, displayName: vehicleType.capitalized, symbolName: "car")
  }
}
