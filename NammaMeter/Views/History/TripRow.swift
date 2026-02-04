import SwiftUI

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
