import SwiftUI

struct EditTripView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: MileageStore
    let trip: Trip
    
    @State private var startDate: Date
    @State private var startOdometer: String
    @State private var endDate: Date
    @State private var endOdometer: String
    @State private var description: String
    
    init(store: MileageStore, trip: Trip) {
        self.store = store
        self.trip = trip
        _startDate = State(initialValue: trip.startDate)
        _startOdometer = State(initialValue: String(format: "%.1f", trip.startOdometer))
        _endDate = State(initialValue: trip.endDate ?? Date())
        _endOdometer = State(initialValue: trip.endOdometer.map { String(format: "%.1f", $0) } ?? "")
        _description = State(initialValue: trip.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Start")) {
                    DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                    HStack {
                        TextField("Odometer", text: $startOdometer)
                            .keyboardType(.decimalPad)
                        Text("km")
                    }
                }
                
                Section(header: Text("End")) {
                    DatePicker("Date", selection: $endDate, displayedComponents: [.date])
                    HStack {
                        TextField("Odometer", text: $endOdometer)
                            .keyboardType(.decimalPad)
                        Text("km")
                    }
                    
                    if let startOdo = Double(startOdometer),
                       let endOdo = Double(endOdometer) {
                        Text("Distance: \(endOdo - startOdo, specifier: "%.1f") km")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    if let startOdo = Double(startOdometer) {
                        let endOdo = Double(endOdometer)
                        store.updateTrip(
                            startDate: startDate,
                            startOdometer: startOdo,
                            endDate: endOdo != nil ? endDate : nil,
                            endOdometer: endOdo,
                            description: description,
                            tripId: trip.id
                        )
                        dismiss()
                    }
                }
                .disabled(Double(startOdometer) == nil)
            )
        }
    }
} 