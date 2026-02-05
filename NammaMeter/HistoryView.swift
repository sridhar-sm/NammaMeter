import SwiftUI

struct HistoryView: View {
  @State private var searchText = ""
  @State private var selection = Set<UUID>()
  @State private var editMode: EditMode = .inactive

  var body: some View {
    NavigationStack {
      HistoryContentView(searchText: $searchText, selection: $selection, editMode: $editMode)
        .environment(\.editMode, $editMode)
    }
  }
}

private struct HistoryContentView: View {
  @Environment(TripStore.self) private var tripStore
  @Binding var searchText: String
  @Binding var selection: Set<UUID>
  @Binding var editMode: EditMode
  @FocusState private var searchFocused: Bool

  var body: some View {
    ZStack {
      NammaBackground()
      tripList
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        HistoryToolbarTitle()
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: editMode) { _, newValue in
      if newValue != .active {
        selection.removeAll()
      }
    }
    .onChange(of: searchText) { _, _ in
      if editMode != .active {
        selection.removeAll()
      }
    }
  }

  private var tripList: some View {
    List(selection: $selection) {
      HistoryListContent(
        trips: tripStore.trips,
        filteredTrips: filteredTrips,
        isEditing: isEditing,
        onDeleteFiltered: deleteFiltered
      )
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .safeAreaInset(edge: .top, spacing: 0) {
      VStack(spacing: 6) {
        HistorySearchBar(searchText: $searchText, searchFocused: $searchFocused)
        if !tripStore.trips.isEmpty {
          HistoryActionBar(
            isEditing: isEditing,
            showSelectAll: isEditing && !filteredTrips.isEmpty,
            showDelete: isEditing && !selection.isEmpty,
            isAllSelected: isAllSelected,
            onToggleSelectAll: toggleSelectAll,
            onDeleteSelected: deleteSelected,
            onToggleEdit: { editMode = isEditing ? .inactive : .active }
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 4)
      .padding(.bottom, 4)
    }
  }

  private var filteredTrips: [Trip] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return tripStore.trips }
    let query = trimmed.lowercased()
    return tripStore.trips.filter { tripSearchText($0).contains(query) }
  }

  private var isEditing: Bool {
    editMode == .active
  }

  private var filteredTripIds: Set<UUID> {
    Set(filteredTrips.map(\.id))
  }

  private var isAllSelected: Bool {
    !filteredTripIds.isEmpty && selection == filteredTripIds
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

  private func toggleSelectAll() {
    if isAllSelected {
      selection.removeAll()
    } else {
      selection = filteredTripIds
    }
  }
}

#Preview {
  HistoryView()
    .environment(AppContainer.preview)
}
