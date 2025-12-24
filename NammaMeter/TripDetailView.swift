import MapKit
import SwiftUI

struct TripDetailView: View {
  let trip: Trip
  @State private var cameraPosition: MapCameraPosition = .automatic
  @State private var replayIndex: Int = 0
  @State private var isPlaying = false
  @State private var timer: Timer?

  private var coordinates: [CLLocationCoordinate2D] {
    trip.points.map { $0.coordinate }
  }

  var body: some View {
    ZStack {
      NammaBackground()
      ScrollView {
        VStack(spacing: 20) {
          tripSummary
          routeMap
          replayControls
          rateSnapshot
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Trip")
            .font(.nammaDisplay(16))
          Text("ಪ್ರಯಾಣ")
            .font(.nammaBody(11))
        }
      }
    }
    .onAppear {
      if let region = trip.points.coordinateRegion() {
        cameraPosition = .region(region)
      }
    }
    .onDisappear {
      stopReplay()
    }
  }

  private var tripSummary: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(trip.startDate, format: .dateTime.day().month().year().hour().minute())
          .font(.nammaDisplay(16))
        Text("ಪ್ರಯಾಣ ವಿವರ")
          .font(.nammaBody(12))
          .foregroundStyle(Theme.ink.opacity(0.7))
      }

      HStack(spacing: 12) {
        SummaryChip(title: "Fare", value: trip.fare.formatted(.currency(code: "INR")))
        SummaryChip(title: "Distance", value: "\((trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2)))) km")
        SummaryChip(title: "Time", value: formattedElapsed(trip.duration))
      }

      HStack(spacing: 8) {
        ConditionBadge(title: "Rain", subtitle: "ಮಳೆ", isOn: trip.conditions.isRaining)
        ConditionBadge(title: "Night", subtitle: "ರಾತ್ರಿ", isOn: trip.conditions.isNight)
        ConditionBadge(title: "Traffic", subtitle: "ಟ್ರಾಫಿಕ್", isOn: trip.conditions.isHeavyTraffic)
      }
    }
    .cardStyle()
  }

  private var routeMap: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Route")
            .font(.nammaDisplay(16))
          Text("ಮಾರ್ಗ")
            .font(.nammaBody(12))
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
        Spacer()
      }

      Map(position: $cameraPosition) {
        if coordinates.count > 1 {
          MapPolyline(coordinates: coordinates)
            .stroke(Theme.ink, lineWidth: 4)
        }
        if let start = coordinates.first {
          Marker("Start", coordinate: start)
        }
        if let end = coordinates.last {
          Marker("End", coordinate: end)
        }
        if let replayCoordinate = replayCoordinate {
          Annotation("Replay", coordinate: replayCoordinate) {
            Image(systemName: "car.fill")
              .foregroundStyle(Theme.coral)
              .padding(6)
              .background(Color.white.opacity(0.9))
              .clipShape(Circle())
          }
        }
      }
      .frame(height: 240)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .cardStyle()
  }

  private var replayControls: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Replay")
            .font(.nammaDisplay(16))
          Text("ಮರುನಿರ್ವಹಣೆ")
            .font(.nammaBody(12))
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
        Spacer()
        Button {
          isPlaying ? stopReplay() : startReplay()
        } label: {
          Text(isPlaying ? "Pause" : "Play")
            .font(.nammaDisplay(14))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.mango.opacity(0.6))
            .clipShape(Capsule())
        }
        .disabled(coordinates.count < 2)
      }

      Slider(
        value: Binding(
          get: { Double(replayIndex) },
          set: { replayIndex = Int($0) }
        ),
        in: 0...Double(max(coordinates.count - 1, 0)),
        step: 1
      )
      .disabled(coordinates.count < 2)

      if let point = trip.points[safe: replayIndex] {
        Text("\(point.timestamp.formatted(date: .omitted, time: .standard))")
          .font(.nammaBody(12))
          .foregroundStyle(Theme.ink.opacity(0.7))
      }
    }
    .cardStyle()
  }

  private var rateSnapshot: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Rates Used")
            .font(.nammaDisplay(16))
          Text("ಬಳಸಿದ ದರಗಳು")
            .font(.nammaBody(12))
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
        Spacer()
        Text("x\(trip.multiplier.formatted(.number.precision(.fractionLength(2))))")
          .font(.nammaDisplay(14))
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Theme.lime.opacity(0.4))
          .clipShape(Capsule())
      }

      HStack {
        RateLine(title: "Base Fare", subtitle: "ಮೂಲ ಬಾಡಿಗೆ", value: trip.rateSnapshot.baseFare)
        RateLine(title: "Per Km", subtitle: "ಪ್ರತಿ ಕಿಮೀ", value: trip.rateSnapshot.perKmRate)
      }
      HStack {
        RateLine(title: "Per Minute", subtitle: "ಪ್ರತಿ ನಿಮಿಷ", value: trip.rateSnapshot.perMinuteRate)
        RateLine(title: "Min Fare", subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ", value: trip.rateSnapshot.minFare)
      }
    }
    .cardStyle()
  }

  private var replayCoordinate: CLLocationCoordinate2D? {
    guard coordinates.indices.contains(replayIndex) else { return nil }
    return coordinates[replayIndex]
  }

  private func startReplay() {
    stopReplay()
    guard coordinates.count > 1 else { return }
    if replayIndex >= coordinates.count - 1 {
      replayIndex = 0
    }
    isPlaying = true
    timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
      if replayIndex < coordinates.count - 1 {
        replayIndex += 1
      } else {
        stopReplay()
      }
    }
  }

  private func stopReplay() {
    timer?.invalidate()
    timer = nil
    isPlaying = false
  }
}

struct SummaryChip: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.nammaBody(10))
        .foregroundStyle(Theme.ink.opacity(0.7))
      Text(value)
        .font(.nammaDisplay(14))
        .foregroundStyle(Theme.ink)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .background(Theme.card)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct ConditionBadge: View {
  let title: String
  let subtitle: String
  let isOn: Bool

  var body: some View {
    VStack(spacing: 4) {
      Text(title)
        .font(.nammaDisplay(11))
      Text(subtitle)
        .font(.nammaBody(9))
    }
    .foregroundStyle(isOn ? Theme.ink : Theme.ink.opacity(0.4))
    .padding(.vertical, 6)
    .padding(.horizontal, 10)
    .background(isOn ? Theme.mango.opacity(0.5) : Theme.card)
    .clipShape(Capsule())
  }
}

struct RateLine: View {
  let title: String
  let subtitle: String
  let value: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.nammaBody(11))
      Text(subtitle)
        .font(.nammaBody(9))
        .foregroundStyle(Theme.ink.opacity(0.6))
      Text(value, format: .number.precision(.fractionLength(2)))
        .font(.nammaDisplay(14))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

#Preview {
  TripDetailView(trip: Trip(
    id: UUID(),
    startDate: .now,
    endDate: .now,
    distanceMeters: 5200,
    duration: 880,
    fare: 160,
    points: [],
    conditions: .clear,
    rateSnapshot: RateSnapshot(settings: .bengaluruDefault),
    multiplier: 1.0
  ))
}
