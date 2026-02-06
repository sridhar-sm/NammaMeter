import CoreLocation
import Foundation

protocol GeocodingServiceProtocol: Sendable {
  func cityName(for coordinate: CLLocationCoordinate2D) async -> String?
}

struct GeocodingPlacemark: Sendable {
  let locality: String?
  let subAdministrativeArea: String?
  let administrativeArea: String?
}

actor GeocodingService: GeocodingServiceProtocol {
  typealias ReverseGeocode = @Sendable (CLLocationCoordinate2D) async throws -> GeocodingPlacemark?

  private var cache: [CacheKey: String] = [:]
  private var cacheOrder: [CacheKey] = []
  private let maxCacheEntries: Int
  private let reverseGeocode: ReverseGeocode

  init(
    maxCacheEntries: Int = 48,
    reverseGeocode: @escaping ReverseGeocode = GeocodingService.liveReverseGeocode
  ) {
    self.maxCacheEntries = max(1, maxCacheEntries)
    self.reverseGeocode = reverseGeocode
  }

  func cityName(for coordinate: CLLocationCoordinate2D) async -> String? {
    if Task.isCancelled { return nil }
    let key = CacheKey(coordinate: coordinate)
    if let cached = cache[key] {
      return cached
    }

    do {
      guard let placemark = try await reverseGeocode(coordinate) else { return nil }
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

  nonisolated private static func liveReverseGeocode(
    coordinate: CLLocationCoordinate2D
  ) async throws -> GeocodingPlacemark? {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
    guard let placemark = placemarks.first else { return nil }
    return GeocodingPlacemark(
      locality: placemark.locality,
      subAdministrativeArea: placemark.subAdministrativeArea,
      administrativeArea: placemark.administrativeArea
    )
  }

  private struct CacheKey: Hashable {
    let lat: Int
    let lon: Int

    init(coordinate: CLLocationCoordinate2D) {
      let scale = 100.0
      lat = Int((coordinate.latitude * scale).rounded())
      lon = Int((coordinate.longitude * scale).rounded())
    }
  }
}
