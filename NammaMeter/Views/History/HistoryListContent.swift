import SwiftUI

struct HistoryListContent: View {
  let trips: [Trip]
  let filteredTrips: [Trip]
  let isEditing: Bool
  let onDeleteFiltered: (IndexSet) -> Void

  @ViewBuilder
  var body: some View {
    if trips.isEmpty {
      emptyState
    } else if filteredTrips.isEmpty {
      noResultsState
    } else {
      tripRows
    }
  }

  private var emptyState: some View {
    VStack(alignment: .center, spacing: 12) {
      Text("No trips yet")
        .font(FontPresets.Display.subhead)
        .foregroundStyle(Theme.ink)
      Text("ಯಾವುದೇ ಪ್ರಯಾಣಗಳಿಲ್ಲ")
        .font(FontPresets.Body.base)
        .foregroundStyle(Theme.ink.opacity(0.7))
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .listRowBackground(Color.clear)
  }

  private var noResultsState: some View {
    VStack(alignment: .center, spacing: 12) {
      Text("No matching trips")
        .font(FontPresets.Display.subhead)
        .foregroundStyle(Theme.ink)
      Text("ಹೊಂದುವ ಪ್ರಯಾಣಗಳಿಲ್ಲ")
        .font(FontPresets.Body.base)
        .foregroundStyle(Theme.ink.opacity(0.7))
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .listRowBackground(Color.clear)
  }

  private var tripRows: some View {
    ForEach(filteredTrips) { trip in
      tripRow(for: trip)
    }
    .onDelete(perform: onDeleteFiltered)
  }

  @ViewBuilder
  private func tripRow(for trip: Trip) -> some View {
    if isEditing {
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
}
