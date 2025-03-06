import SwiftUI

struct NewTripView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: MileageStore
    
    @State private var startDate = Date()
    @State private var startOdometer = ""
    @State private var endDate = Date()
    @State private var endOdometer = ""
    @State private var description = ""
    @State private var isComplete = false
    
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
                
                Toggle("Trip Complete", isOn: $isComplete)
                
                if isComplete {
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
                }
                
                Section(header: Text("Details")) {
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    if let startOdo = Double(startOdometer) {
                        let endOdo = Double(endOdometer)
                        store.updateTrip(
                            startDate: startDate,
                            startOdometer: startOdo,
                            endDate: isComplete ? endDate : nil,
                            endOdometer: isComplete ? endOdo : nil,
                            description: description,
                            tripId: UUID()
                        )
                        dismiss()
                    }
                }
                .disabled(Double(startOdometer) == nil || 
                         (isComplete && Double(endOdometer) == nil))
            )
        }
    }
} 