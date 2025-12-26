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
        VStack(spacing: 2) {
          Text("Trips")
            .font(.nammaDisplay(18))
          Text("ಪ್ರಯಾಣಗಳು")
            .font(.nammaBody(12))
        }
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
      listContent
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .safeAreaInset(edge: .top, spacing: 0) {
      VStack(spacing: 6) {
        searchBar
        if !tripStore.trips.isEmpty {
          actionBar
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 4)
      .padding(.bottom, 4)
    }
  }

  @ViewBuilder
  private var listContent: some View {
    if tripStore.trips.isEmpty {
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
        .font(.nammaDisplay(16))
        .foregroundStyle(Theme.ink)
      Text("ಯಾವುದೇ ಪ್ರಯಾಣಗಳಿಲ್ಲ")
        .font(.nammaBody(12))
        .foregroundStyle(Theme.ink.opacity(0.7))
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .listRowBackground(Color.clear)
  }

  private var noResultsState: some View {
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
  }

  private var tripRows: some View {
    ForEach(filteredTrips) { trip in
      tripRow(for: trip)
    }
    .onDelete(perform: deleteFiltered)
  }

  @ViewBuilder
  private func tripRow(for trip: Trip) -> some View {
    if editMode == .active {
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

  private var selectAllButton: some View {
    Button {
      toggleSelectAll()
    } label: {
      mangoPillLabel(isAllSelected ? "Deselect All" : "Select All")
    }
    .accessibilityLabel(isAllSelected ? "Deselect All" : "Select All")
  }

  private var actionBar: some View {
    HStack(spacing: 12) {
      if isEditing && !filteredTrips.isEmpty {
        selectAllButton
      }
      Spacer()
      if isEditing && !selection.isEmpty {
        Button(role: .destructive) {
          deleteSelected()
        } label: {
          Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      editToggleButton
    }
  }

  private var editToggleButton: some View {
    Button {
      editMode = isEditing ? .inactive : .active
    } label: {
      mangoPillLabel(isEditing ? "Done" : "Edit")
    }
    .accessibilityLabel(isEditing ? "Done" : "Edit")
  }

  private func mangoPillLabel(_ title: String) -> some View {
    Text(title)
      .font(.nammaDisplay(13))
      .foregroundStyle(Theme.ink)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(Theme.mango.opacity(0.6))
      .clipShape(Capsule())
  }

  private var searchBar: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(Color(uiColor: .secondaryLabel))
      TextField("Search trips · ಹುಡುಕಿ", text: $searchText)
        .font(.system(size: 16))
        .foregroundStyle(Color(uiColor: .label))
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .focused($searchFocused)
        .submitLabel(.search)
      if !searchText.isEmpty {
        Button {
          searchText = ""
          searchFocused = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search")
      } else if searchFocused {
        Button {
          searchFocused = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel search")
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(uiColor: .systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(Color(uiColor: .systemGray4), lineWidth: 0.5)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
