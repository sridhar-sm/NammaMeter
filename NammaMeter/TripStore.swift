import CoreLocation
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class TripStore {
  private(set) var trips: [Trip] = [] {
    didSet {
      guard isLoaded else { return }
      saveTask?.cancel()
      saveTask = Task { await save() }
    }
  }

  @ObservationIgnored private let persistence: TripPersistence
  @ObservationIgnored private var isLoaded = false
  @ObservationIgnored private var saveTask: Task<Void, Never>?
  @ObservationIgnored private let geocoder: any GeocodingServiceProtocol

  init(
    fileURL: URL = TripStore.defaultURL,
    geocoder: any GeocodingServiceProtocol = GeocodingService()
  ) {
    self.persistence = TripPersistence(url: fileURL)
    self.geocoder = geocoder
    Task { await load() }
  }

  func add(_ trip: Trip) {
    trips.insert(trip, at: 0)
  }

  func delete(at offsets: IndexSet) {
    for offset in offsets.sorted(by: >) {
      trips.remove(at: offset)
    }
  }

  func delete(ids: Set<UUID>) {
    guard !ids.isEmpty else { return }
    trips.removeAll { ids.contains($0.id) }
  }

  func deleteAll() {
    trips.removeAll()
  }

  func update(_ tripId: UUID, mutate: (inout Trip) -> Void) {
    guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
    var updated = trips[index]
    mutate(&updated)
    trips[index] = updated
  }

  func trip(for tripId: UUID) -> Trip? {
    trips.first(where: { $0.id == tripId })
  }

  func resolveStartLocation(for trip: Trip) async {
    guard trip.startLocationName == nil else { return }
    guard let start = trip.points.first else { return }
    if Task.isCancelled { return }
    guard let city = await geocoder.cityName(for: start.coordinate) else { return }
    if Task.isCancelled { return }
    update(trip.id) { $0.startLocationName = city }
  }

  private func load() async {
    if let decoded = await persistence.load() {
      trips = decoded
      Log.persistence.info("Loaded \(decoded.count) trips from storage")
    } else {
      Log.persistence.info("No existing trips found")
    }
    isLoaded = true
  }

  private func save() async {
    guard !Task.isCancelled, isLoaded else { return }
    await persistence.save(trips)
    Log.persistence.debug("Saved \(self.trips.count) trips to storage")
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("trips.json")
  }
}

private actor TripPersistence {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func load() -> [Trip]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode([Trip].self, from: data)
  }

  func save(_ trips: [Trip]) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(trips) else { return }
    try? data.write(to: url, options: [.atomic])
  }
}
