import Combine
import Foundation

final class TripStore: ObservableObject {
  @Published private(set) var trips: [Trip] = [] {
    didSet {
      guard isLoaded else { return }
      save()
    }
  }

  private let fileURL: URL
  private var isLoaded = false

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

  func deleteAll() {
    trips.removeAll()
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

  private static var defaultURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("trips.json")
  }
}
