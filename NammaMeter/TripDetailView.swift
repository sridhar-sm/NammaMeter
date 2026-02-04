import MapKit
import SwiftUI

struct TripDetailView: View {
  @Environment(TripStore.self) private var tripStore
  let tripId: UUID
  @State private var cameraPosition: MapCameraPosition = .automatic
  @State private var replayIndex: Int = 0
  @State private var isPlaying = false
  @State private var replayTask: Task<Void, Never>?

  var body: some View {
    if let trip = tripStore.trip(for: tripId) {
      content(for: trip)
        .onAppear {
          if let region = trip.points.coordinateRegion() {
            cameraPosition = .region(region)
          }
        }
        .onDisappear {
          stopReplay()
        }
    } else {
      Text("Trip not found")
        .font(FontPresets.Display.subhead)
        .foregroundStyle(Theme.ink)
    }
  }

  private func content(for trip: Trip) -> some View {
    let coordinates = trip.points.map { $0.coordinate }

    return ZStack {
      NammaBackground()
      ScrollView {
        VStack(spacing: 20) {
          tripSummary(for: trip)
          routeMap(for: trip, coordinates: coordinates)
          replayControls(for: trip, coordinates: coordinates)
          rateSnapshot(for: trip)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Trip")
            .font(FontPresets.Display.subhead)
          Text("ಪ್ರಯಾಣ")
            .font(FontPresets.Body.small)
        }
      }
    }
  }

  private var nameBinding: Binding<String> {
    Binding(
      get: { tripStore.trip(for: tripId)?.name ?? "" },
      set: { newValue in
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        tripStore.update(tripId) { $0.name = trimmed.isEmpty ? nil : trimmed }
      }
    )
  }

  private func tripSummary(for trip: Trip) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Trip Name")
          .font(FontPresets.Display.small)
        Text("ಪ್ರಯಾಣ ಹೆಸರು")
          .font(FontPresets.Body.xSmall)
          .foregroundStyle(Theme.ink.opacity(0.7))

        TextField("Add a name", text: nameBinding)
          .font(FontPresets.Display.subhead)
          .padding(10)
          .background(Color.white.opacity(0.9))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(trip.startDate, format: .dateTime.day().month().year().hour().minute())
          .font(FontPresets.Display.detail)
        Text(trip.startLocationName ?? "Locating...")
          .font(FontPresets.Body.small)
          .foregroundStyle(Theme.ink.opacity(0.7))
      }

      if let cityName = trip.rateSnapshot.cityName {
        HStack(spacing: 6) {
          Image(systemName: "building.2")
            .font(.system(size: 12))
            .foregroundStyle(Theme.ink.opacity(0.7))
          Text(cityName)
            .font(FontPresets.Body.base)
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
      }

      HStack(spacing: 12) {
        SummaryChip(title: "Fare", value: trip.fare.formatted(.currency(code: "INR")))
        SummaryChip(title: "Distance", value: "\((trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2)))) km")
        SummaryChip(title: "Time", value: formattedElapsed(trip.duration))
      }

      if trip.waitingDuration > 0 {
        SummaryChip(title: "Wait", value: formattedElapsed(trip.waitingDuration))
      }

      ConditionBadge(title: "Night", subtitle: "ರಾತ್ರಿ", isOn: trip.conditions.isNight)
    }
    .cardStyle()
  }

  private func routeMap(for trip: Trip, coordinates: [CLLocationCoordinate2D]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Route")
            .font(FontPresets.Display.subhead)
          Text("ಮಾರ್ಗ")
            .font(FontPresets.Body.base)
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
        if let replayCoordinate = replayCoordinate(in: coordinates) {
          Annotation("Replay", coordinate: replayCoordinate, anchor: .bottom) {
            AutoLocationMarker()
          }
        }
      }
      .frame(height: 240)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .cardStyle()
  }

  private func replayControls(for trip: Trip, coordinates: [CLLocationCoordinate2D]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Replay")
            .font(FontPresets.Display.subhead)
          Text("ಮರುನಿರ್ವಹಣೆ")
            .font(FontPresets.Body.base)
            .foregroundStyle(Theme.ink.opacity(0.7))
        }
        Spacer()
        Button {
          isPlaying ? stopReplay() : startReplay(count: coordinates.count)
        } label: {
          Text(isPlaying ? "Pause" : "Play")
            .font(FontPresets.Display.label)
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
          .font(FontPresets.Body.base)
          .foregroundStyle(Theme.ink.opacity(0.7))
      }
    }
    .cardStyle()
  }

  private func rateSnapshot(for trip: Trip) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Rates Used")
            .font(FontPresets.Display.subhead)
          if let cityName = trip.rateSnapshot.cityName {
            Text("\(cityName) rates")
              .font(FontPresets.Body.base)
              .foregroundStyle(Theme.ink.opacity(0.7))
          } else {
            Text("ಬಳಸಿದ ದರಗಳು")
              .font(FontPresets.Body.base)
              .foregroundStyle(Theme.ink.opacity(0.7))
          }
        }
        Spacer()
        Text("x\(trip.multiplier.formatted(.number.precision(.fractionLength(2))))")
          .font(FontPresets.Display.label)
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
        RateLine(title: "Min Fare", subtitle: "ಕನಿಷ್ಠ ಬಾಡಿಗೆ", value: trip.rateSnapshot.minFare)
        RateLine(title: "Free Wait", subtitle: "ಉಚಿತ ನಿಲ್ಲಿಕೆ", value: trip.rateSnapshot.freeWaitMinutes)
      }
      HStack {
        RateLine(title: "Wait Interval", subtitle: "ನಿಲ್ಲಿಕೆ ಮಧ್ಯಂತರ", value: trip.rateSnapshot.waitIntervalMinutes)
        RateLine(title: "Per Interval", subtitle: "ಪ್ರತಿ ಮಧ್ಯಂತರ", value: trip.rateSnapshot.waitIntervalCharge)
      }
    }
    .cardStyle()
  }

  private func replayCoordinate(in coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
    guard coordinates.indices.contains(replayIndex) else { return nil }
    return coordinates[replayIndex]
  }

  private func startReplay(count: Int) {
    stopReplay()
    guard count > 1 else { return }
    if replayIndex >= count - 1 {
      replayIndex = 0
    }
    isPlaying = true
    replayTask = Task { @MainActor in
      let clock = ContinuousClock()
      while !Task.isCancelled {
        try? await clock.sleep(for: .milliseconds(400))
        if replayIndex < count - 1 {
          replayIndex += 1
        } else {
          isPlaying = false
          replayTask = nil
          break
        }
      }
    }
  }

  private func stopReplay() {
    replayTask?.cancel()
    replayTask = nil
    isPlaying = false
  }
}

struct SummaryChip: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(FontPresets.Body.xSmall)
        .foregroundStyle(Theme.ink.opacity(0.7))
      Text(value)
        .font(FontPresets.Display.label)
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
        .font(FontPresets.Display.tiny)
      Text(subtitle)
        .font(FontPresets.Body.micro)
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
        .font(FontPresets.Body.small)
      Text(subtitle)
        .font(FontPresets.Body.micro)
        .foregroundStyle(Theme.ink.opacity(0.6))
      Text(value, format: .number.precision(.fractionLength(2)))
        .font(FontPresets.Display.label)
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
  let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent("preview-trips.json")
  let store = TripStore(fileURL: previewURL)
  let trip = Trip(
    id: UUID(),
    startDate: .now,
    endDate: .now,
    distanceMeters: 5200,
    duration: 880,
    fare: 160,
    points: [],
    conditions: .clear,
    rateSnapshot: RateSnapshot(settings: .bengaluruDefault),
    multiplier: 1.0,
    name: "MG Road to Indiranagar",
    startLocationName: "Bengaluru",
    waitingDuration: 140
  )
  store.deleteAll()
  store.add(trip)

  return TripDetailView(tripId: trip.id)
    .environment(store)
}
