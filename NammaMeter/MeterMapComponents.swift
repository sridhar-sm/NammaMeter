import MapKit
import SwiftUI
import UIKit

// MARK: - Live Route Map

struct LiveRouteMap: View {
  let points: [TripPoint]
  let followLatest: Bool
  @State private var cameraPosition: MapCameraPosition = .automatic

  var body: some View {
    Group {
      if TestEnvironment.isRunningTests {
        Color.clear
      } else {
        Map(position: $cameraPosition) {
          if points.count > 1 {
            MapPolyline(coordinates: points.map { $0.coordinate })
              .stroke(Theme.ink, lineWidth: 4)
          }
          if let start = points.first?.coordinate {
            Marker("Start", coordinate: start)
          }
          if let end = points.last?.coordinate {
            Annotation("Now", coordinate: end, anchor: .bottom) {
              AutoLocationMarker()
            }
          }
        }
      }
    }
    .onAppear {
      updateCamera(points)
    }
    .onChange(of: points) { _, newPoints in
      updateCamera(newPoints)
    }
  }

  private func updateCamera(_ points: [TripPoint]) {
    guard let last = points.last else { return }

    if followLatest {
      let region = MKCoordinateRegion(center: last.coordinate, latitudinalMeters: 700, longitudinalMeters: 700)
      withAnimation(.easeInOut(duration: 0.5)) {
        cameraPosition = .region(region)
      }
    } else if let region = points.coordinateRegion() {
      cameraPosition = .region(region)
    }
  }
}

// MARK: - Auto Location Marker

struct AutoLocationMarker: View {
  var body: some View {
    VStack(spacing: 4) {
      AutoRickshawIcon()
        .padding(6)
        .background(Theme.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
      Circle()
        .fill(Theme.ink.opacity(0.35))
        .frame(width: 6, height: 6)
    }
    .shadow(color: Theme.pastelShadow(), radius: 6, x: 0, y: 3)
  }
}

// MARK: - Auto Rickshaw Icon

struct AutoRickshawIcon: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(Theme.mango)
        .frame(width: 28, height: 14)
      RoundedRectangle(cornerRadius: 3, style: .continuous)
        .fill(Theme.ink.opacity(0.85))
        .frame(width: 14, height: 8)
        .offset(x: -4, y: -4)
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(Theme.sky.opacity(0.8))
        .frame(width: 8, height: 5)
        .offset(x: 6, y: -1)
      Circle()
        .fill(Theme.ink)
        .frame(width: 5, height: 5)
        .offset(x: -7, y: 6)
      Circle()
        .fill(Theme.ink)
        .frame(width: 5, height: 5)
        .offset(x: 7, y: 6)
    }
  }
}

// MARK: - Page Swipe Disabler

struct PageSwipeDisabler: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    UIView(frame: .zero)
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    DispatchQueue.main.async {
      guard let scrollView = findPagingScrollView(from: uiView) else { return }
      if scrollView.isScrollEnabled {
        scrollView.isScrollEnabled = false
      }
    }
  }

  private func findPagingScrollView(from view: UIView) -> UIScrollView? {
    var root: UIView? = view
    while let parent = root?.superview {
      root = parent
    }
    guard let rootView = root else { return nil }
    return findPagingScrollView(in: rootView)
  }

  private func findPagingScrollView(in view: UIView) -> UIScrollView? {
    if let scrollView = view as? UIScrollView, scrollView.isPagingEnabled {
      return scrollView
    }
    for subview in view.subviews {
      if let found = findPagingScrollView(in: subview) {
        return found
      }
    }
    return nil
  }
}
