import CoreLocation
import Foundation
import Observation

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
  @ObservationIgnored private let geocoder = GeocodingService()

  init(fileURL: URL = TripStore.defaultURL) {
    self.persistence = TripPersistence(url: fileURL)
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
    let location = CLLocation(latitude: start.latitude, longitude: start.longitude)
    guard let city = await geocoder.cityName(for: location) else { return }
    if Task.isCancelled { return }
    update(trip.id) { $0.startLocationName = city }
  }

  private func load() async {
    if let decoded = await persistence.load() {
      trips = decoded
    }
    isLoaded = true
  }

  private func save() async {
    guard !Task.isCancelled, isLoaded else { return }
    await persistence.save(trips)
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

private actor GeocodingService {
  private let geocoder = CLGeocoder()
  private var cache: [CacheKey: String] = [:]
  private var cacheOrder: [CacheKey] = []
  private let maxCacheEntries = 48

  func cityName(for location: CLLocation) async -> String? {
    if Task.isCancelled { return nil }
    let key = CacheKey(location: location)
    if let cached = cache[key] {
      return cached
    }
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      guard let placemark = placemarks.first else { return nil }
      let city = placemark.locality
        ?? placemark.subAdministrativeArea
        ?? placemark.administrativeArea
      guard let city, !city.isEmpty else { return nil }
      insertCache(city, for: key)
      return city
    } catch {
      return nil
    }
  }

  private func insertCache(_ city: String, for key: CacheKey) {
    cache[key] = city
    cacheOrder.removeAll { $0 == key }
    cacheOrder.append(key)
    if cacheOrder.count > maxCacheEntries, let oldest = cacheOrder.first {
      cacheOrder.removeFirst()
      cache.removeValue(forKey: oldest)
    }
  }

  private struct CacheKey: Hashable {
    let lat: Int
    let lon: Int

    init(location: CLLocation) {
      let scale = 100.0
      lat = Int((location.coordinate.latitude * scale).rounded())
      lon = Int((location.coordinate.longitude * scale).rounded())
    }
  }
}
