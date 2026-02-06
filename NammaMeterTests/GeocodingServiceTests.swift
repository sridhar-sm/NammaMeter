import CoreLocation
import XCTest
@testable import NammaMeter

final class GeocodingServiceTests: XCTestCase {

  func testCityNamePrefersLocality() async {
    let resolver = ReverseGeocodeStub(
      outcomes: [
        .placemark(
          GeocodingPlacemark(
            locality: "Bengaluru",
            subAdministrativeArea: "Bangalore Urban",
            administrativeArea: "Karnataka"
          )
        )
      ]
    )
    let service = GeocodingService(reverseGeocode: { coordinate in
      try await resolver.resolve(coordinate)
    })

    let city = await service.cityName(for: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946))
    let callCount = await resolver.callCount()

    XCTAssertEqual(city, "Bengaluru")
    XCTAssertEqual(callCount, 1)
  }

  func testCityNameFallsBackToSubAdministrativeArea() async {
    let resolver = ReverseGeocodeStub(
      outcomes: [
        .placemark(
          GeocodingPlacemark(
            locality: nil,
            subAdministrativeArea: "Bangalore Urban",
            administrativeArea: "Karnataka"
          )
        )
      ]
    )
    let service = GeocodingService(reverseGeocode: { coordinate in
      try await resolver.resolve(coordinate)
    })

    let city = await service.cityName(for: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946))

    XCTAssertEqual(city, "Bangalore Urban")
  }

  func testCityNameUsesRoundedCoordinateCache() async {
    let resolver = ReverseGeocodeStub(
      outcomes: [
        .placemark(
          GeocodingPlacemark(
            locality: "Mysuru",
            subAdministrativeArea: nil,
            administrativeArea: nil
          )
        )
      ]
    )
    let service = GeocodingService(reverseGeocode: { coordinate in
      try await resolver.resolve(coordinate)
    })

    let first = await service.cityName(for: CLLocationCoordinate2D(latitude: 12.3451, longitude: 77.9871))
    let second = await service.cityName(for: CLLocationCoordinate2D(latitude: 12.3452, longitude: 77.9872))
    let callCount = await resolver.callCount()

    XCTAssertEqual(first, "Mysuru")
    XCTAssertEqual(second, "Mysuru")
    XCTAssertEqual(callCount, 1)
  }

  func testCityNameReturnsNilWhenResolverThrows() async {
    let resolver = ReverseGeocodeStub(outcomes: [.failure])
    let service = GeocodingService(reverseGeocode: { coordinate in
      try await resolver.resolve(coordinate)
    })

    let city = await service.cityName(for: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946))
    let callCount = await resolver.callCount()

    XCTAssertNil(city)
    XCTAssertEqual(callCount, 1)
  }

  func testCityNameEvictsLeastRecentlyUsedEntryWhenCacheIsFull() async {
    let resolver = ReverseGeocodeStub(
      outcomes: [
        .placemark(GeocodingPlacemark(locality: "City One", subAdministrativeArea: nil, administrativeArea: nil)),
        .placemark(GeocodingPlacemark(locality: "City Two", subAdministrativeArea: nil, administrativeArea: nil)),
        .placemark(GeocodingPlacemark(locality: "City One Reloaded", subAdministrativeArea: nil, administrativeArea: nil))
      ]
    )
    let service = GeocodingService(maxCacheEntries: 1, reverseGeocode: { coordinate in
      try await resolver.resolve(coordinate)
    })
    let firstCoordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
    let secondCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)

    _ = await service.cityName(for: firstCoordinate)
    _ = await service.cityName(for: secondCoordinate)
    let firstAgain = await service.cityName(for: firstCoordinate)
    let callCount = await resolver.callCount()

    XCTAssertEqual(firstAgain, "City One Reloaded")
    XCTAssertEqual(callCount, 3)
  }
}

private actor ReverseGeocodeStub {
  enum Outcome: Sendable {
    case placemark(GeocodingPlacemark?)
    case failure
  }

  private var outcomes: [Outcome]
  private var requests = 0

  init(outcomes: [Outcome]) {
    self.outcomes = outcomes
  }

  func resolve(_ coordinate: CLLocationCoordinate2D) async throws -> GeocodingPlacemark? {
    requests += 1
    guard !outcomes.isEmpty else { throw StubError.missingOutcome }
    switch outcomes.removeFirst() {
    case let .placemark(value):
      return value
    case .failure:
      throw StubError.forcedFailure
    }
  }

  func callCount() -> Int {
    requests
  }
}

private enum StubError: Error {
  case forcedFailure
  case missingOutcome
}
