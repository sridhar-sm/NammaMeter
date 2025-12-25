import SwiftUI

struct HistoryView: View {
  @Environment(TripStore.self) private var tripStore
  @Environment(\.editMode) private var editMode
  @State private var searchText = ""
  @State private var selection = Set<UUID>()

  var body: some View {
    NavigationStack {
      ZStack {
        NammaBackground()
        List(selection: $selection) {
          if tripStore.trips.isEmpty {
            VStack(alignment: .center, spacing: 12) {
              Text("No trips yet")
                .font(.nammaDisplay(16))
                .foregroundStyle(Theme.ink)
              Text("ಯಾವುದೇ ಪ್ರಯಾಣಗಳಿಲ್ಲ")
                .font(.nammaBody(12))
                .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .listRowBackground(Color.clear)
          } else if filteredTrips.isEmpty {
            VStack(alignment: .center, spacing: 12) {
              Text("No matching trips")
                .font(.nammaDisplay(16))
                .foregroundStyle(Theme.ink)
              Text("ಹೊಂದುವ ಪ್ರಯಾಣಗಳಿಲ್ಲ")
                .font(.nammaBody(12))
                .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .listRowBackground(Color.clear)
          } else {
            ForEach(filteredTrips) { trip in
              if editMode?.wrappedValue == .active {
                TripRow(trip: trip)
                  .tag(trip.id)
                  .listRowBackground(Theme.card)
              } else {
                NavigationLink {
                  TripDetailView(tripId: trip.id)
                } label: {
                  TripRow(trip: trip)
                }
                .tag(trip.id)
                .listRowBackground(Theme.card)
              }
            }
            .onDelete(perform: deleteFiltered)
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack(spacing: 2) {
            Text("Trips")
              .font(.nammaDisplay(18))
            Text("ಪ್ರಯಾಣಗಳು")
              .font(.nammaBody(12))
          }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          if !selection.isEmpty {
            Button(role: .destructive) {
              deleteSelected()
            } label: {
              Image(systemName: "trash")
            }
          }
          EditButton()
        }
      }
      .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
      .onChange(of: editMode?.wrappedValue) { _, newValue in
        if newValue != .active {
          selection.removeAll()
        }
      }
      .onChange(of: searchText) { _, _ in
        if editMode?.wrappedValue != .active {
          selection.removeAll()
        }
      }
    }
  }

  private var filteredTrips: [Trip] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return tripStore.trips }
    let query = trimmed.lowercased()
    return tripStore.trips.filter { tripSearchText($0).contains(query) }
  }

  private func tripSearchText(_ trip: Trip) -> String {
    let dateText = trip.startDate.formatted(date: .abbreviated, time: .shortened)
    let durationText = formattedElapsed(trip.duration)
    let distanceText = (trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2))) + " km"
    return [
      trip.name,
      trip.startLocationName,
      dateText,
      durationText,
      distanceText
    ]
    .compactMap { $0 }
    .joined(separator: " ")
    .lowercased()
  }

  private func deleteFiltered(at offsets: IndexSet) {
    let ids = offsets.map { filteredTrips[$0].id }
    tripStore.delete(ids: Set(ids))
  }

  private func deleteSelected() {
    tripStore.delete(ids: selection)
    selection.removeAll()
  }
}

struct TripRow: View {
  let trip: Trip

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        if let name = trip.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(name)
            .font(.nammaDisplay(14))
        } else {
          Text(trip.startDate, format: .dateTime.day().month().hour().minute())
            .font(.nammaDisplay(14))
        }
        Spacer()
        Text(trip.fare, format: .currency(code: "INR"))
          .font(.nammaDisplay(14))
      }

      if let name = trip.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(trip.startDate, format: .dateTime.day().month().year().hour().minute())
          .font(.nammaBody(11))
          .foregroundStyle(Theme.ink.opacity(0.7))
      }

      HStack(spacing: 12) {
        Label {
          Text(trip.startLocationName ?? "Locating...")
        } icon: {
          Image(systemName: "mappin.and.ellipse")
        }

        Label {
          Text(formattedElapsed(trip.duration))
        } icon: {
          Image(systemName: "clock")
        }

        Label {
          Text("\((trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2)))) km")
        } icon: {
          Image(systemName: "map")
        }
      }
      .font(.nammaBody(11))
      .foregroundStyle(Theme.ink.opacity(0.7))
    }
    .padding(.vertical, 6)
  }
}

#Preview {
  HistoryView()
    .environment(TripStore())
}
