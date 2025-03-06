import SwiftUI

struct EndTripView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: MileageStore
    let trip: Trip
    @Binding var isPresented: Bool
    
    @State private var endDate = Date()
    @State private var endOdometer = ""
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                
                TextField("End Odometer", text: $endOdometer)
                    .keyboardType(.decimalPad)
                
                Section(footer: Text("Start odometer: \(trip.startOdometer, specifier: "%.1f") km")) {
                    if let odometerValue = Double(endOdometer) {
                        let distance = odometerValue - trip.startOdometer
                        Text("Distance: \(distance, specifier: "%.1f") km")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("End Trip")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    if let endOdometerValue = Double(endOdometer) {
                        store.updateTrip(
                            startDate: trip.startDate,
                            startOdometer: trip.startOdometer,
                            endDate: endDate,
                            endOdometer: endOdometerValue,
                            description: trip.description,
                            tripId: trip.id
                        )
                        isPresented = false
                    }
                }
                .disabled(Double(endOdometer) == nil)
            )
        }
    }
} 