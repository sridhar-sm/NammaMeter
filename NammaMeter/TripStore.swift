import Combine
import CoreLocation
import Foundation

@MainActor
final class TripStore: ObservableObject {
  @Published private(set) var trips: [Trip] = [] {
    didSet {
      guard isLoaded else { return }
      save()
    }
  }

  private let fileURL: URL
  private var isLoaded = false
  private let geocoder = CLGeocoder()

  init(fileURL: URL = TripStore.defaultURL) {
    self.fileURL = fileURL
    load()
    isLoaded = true
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
    let location = CLLocation(latitude: start.latitude, longitude: start.longitude)
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      guard let placemark = placemarks.first else { return }
      let city = placemark.locality
        ?? placemark.subAdministrativeArea
        ?? placemark.administrativeArea
      guard let city, !city.isEmpty else { return }
      update(trip.id) { $0.startLocationName = city }
    } catch {
      return
    }
  }

  private func load() {
    guard let data = try? Data(contentsOf: fileURL) else { return }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let decoded = try? decoder.decode([Trip].self, from: data) else { return }
    trips = decoded
  }

  private func save() {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(trips) else { return }
    try? data.write(to: fileURL, options: [.atomic])
  }

  nonisolated static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("trips.json")
  }
}
