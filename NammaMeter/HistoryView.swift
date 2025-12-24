import SwiftUI

struct HistoryView: View {
  @EnvironmentObject var tripStore: TripStore

  var body: some View {
    NavigationStack {
      ZStack {
        NammaBackground()
        List {
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
          } else {
            ForEach(tripStore.trips) { trip in
              NavigationLink {
                TripDetailView(trip: trip)
              } label: {
                TripRow(trip: trip)
              }
              .listRowBackground(Theme.card)
            }
            .onDelete(perform: tripStore.delete)
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
      }
    }
  }
}

struct TripRow: View {
  let trip: Trip

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(trip.startDate, format: .dateTime.day().month().hour().minute())
          .font(.nammaDisplay(14))
        Spacer()
        Text(trip.fare, format: .currency(code: "INR"))
          .font(.nammaDisplay(14))
      }

      HStack(spacing: 12) {
        Label {
          Text("\((trip.distanceMeters / 1000).formatted(.number.precision(.fractionLength(2)))) km")
        } icon: {
          Image(systemName: "map")
        }

        Label {
          Text(formattedElapsed(trip.duration))
        } icon: {
          Image(systemName: "clock")
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
    .environmentObject(TripStore())
}
