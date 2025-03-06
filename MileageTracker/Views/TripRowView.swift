import SwiftUI

struct TripRowView: View {
    let trip: Trip
    @ObservedObject var store: MileageStore
    @State private var showingEndTripSheet = false
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: { showingEditSheet = true }) {
            VStack(alignment: .leading) {
                Text(trip.description)
                    .font(.headline)
                
                HStack {
                    Text("Start: \(trip.startOdometer, specifier: "%.1f") km")
                    Spacer()
                    Text(trip.startDate, style: .date)
                }
                .font(.subheadline)
                
                if let endOdometer = trip.endOdometer, let endDate = trip.endDate {
                    HStack {
                        Text("End: \(endOdometer, specifier: "%.1f") km")
                        Spacer()
                        Text(endDate, style: .date)
                    }
                    .font(.subheadline)
                    
                    if let distance = trip.distance {
                        Text("Distance: \(distance, specifier: "%.1f") km")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack {
                        Text("In Progress")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("End Trip") {
                            showingEndTripSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEndTripSheet) {
            EndTripView(store: store, trip: trip, isPresented: $showingEndTripSheet)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripView(store: store, trip: trip)
        }
    }
} 