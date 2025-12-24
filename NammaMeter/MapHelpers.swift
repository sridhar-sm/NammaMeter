import MapKit

extension Array where Element == TripPoint {
  func coordinateRegion(padding: CLLocationDegrees = 0.005) -> MKCoordinateRegion? {
    guard !isEmpty else { return nil }
    let lats = map { $0.latitude }
    let longs = map { $0.longitude }
    guard let minLat = lats.min(),
          let maxLat = lats.max(),
          let minLon = longs.min(),
          let maxLon = longs.max() else { return nil }

    let center = CLLocationCoordinate2D(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLon + maxLon) / 2
    )

    let span = MKCoordinateSpan(
      latitudeDelta: Swift.max((maxLat - minLat) * 1.6, padding),
      longitudeDelta: Swift.max((maxLon - minLon) * 1.6, padding)
    )

    return MKCoordinateRegion(center: center, span: span)
  }
}
