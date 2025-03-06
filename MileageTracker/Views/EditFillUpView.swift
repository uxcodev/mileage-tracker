import SwiftUI
import CoreLocation
import Combine

struct EditFillUpView: View {
    @ObservedObject var store: MileageStore
    let fillUp: FuelFillUp
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @StateObject private var locationManager = LocationManager()
    
    // Separate state properties for form fields
    @State private var volumeText: String
    @State private var amountText: String
    @State private var locationText: String
    @State private var odometerText: String
    
    init(store: MileageStore, fillUp: FuelFillUp) {
        self.store = store
        self.fillUp = fillUp
        
        // Initialize text fields with formatted values
        _volumeText = State(initialValue: String(format: "%.1f", fillUp.volume))
        _amountText = State(initialValue: String(format: "%.2f", fillUp.amount))
        _locationText = State(initialValue: fillUp.location)
        _odometerText = State(initialValue: String(format: "%.0f", fillUp.odometer))
    }
    
    private var pricePerLiter: Double? {
        guard let volume = Double(volumeText),
              let amount = Double(amountText),
              volume > 0 else { return nil }
        return amount / volume
    }
    
    private var consumptionData: (distance: Double, consumption: Double)? {
        guard let currentOdometer = Double(odometerText),
              let prevFillUp = store.fuelFillUps
                .filter({ $0.odometer < currentOdometer })
                .max(by: { $0.odometer < $1.odometer }),
              let volume = Double(volumeText) else { return nil }
        
        let distance = currentOdometer - prevFillUp.odometer
        let consumption = (volume / distance) * 100
        return (distance, consumption)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Volume (L)", text: $volumeText)
                        .keyboardType(.decimalPad)
                        .onChange(of: volumeText) { newValue in
                            volumeText = newValue.filter { "0123456789.".contains($0) }
                        }
                    
                    TextField("Amount ($)", text: $amountText)
                        .keyboardType(.decimalPad)
                        .onChange(of: amountText) { newValue in
                            amountText = newValue.filter { "0123456789.".contains($0) }
                        }
                    
                    TextField("Location", text: $locationText)
                    
                    TextField("Odometer", text: $odometerText)
                        .keyboardType(.decimalPad)
                        .onChange(of: odometerText) { newValue in
                            odometerText = newValue.filter { "0123456789.".contains($0) }
                        }
                }
                
                Section("Calculated Values") {
                    if let price = pricePerLiter {
                        HStack {
                            Text("Price per Liter")
                            Spacer()
                            Text(price, format: .currency(code: "CAD"))
                        }
                    }
                    
                    if let data = consumptionData {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Text("\(Int(data.distance)) km")
                        }
                        
                        HStack {
                            Text("Consumption")
                            Spacer()
                            Text(String(format: "%.1f L/100km", data.consumption))
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Fill-up")
                        }
                    }
                }
            }
            .navigationTitle("Edit Fill-up")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let volume = Double(volumeText),
                       let amount = Double(amountText),
                       let odometer = Double(odometerText) {
                        store.updateFillUp(
                            id: fillUp.id,
                            volume: volume,
                            amount: amount,
                            location: locationText,
                            odometer: odometer
                        )
                        dismiss()
                    }
                }
                .disabled(!isValid)
            )
            .alert("Delete Fill-up", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    store.deleteFillUp(fillUp)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this fill-up? This action cannot be undone.")
            }
        }
        .onChange(of: locationManager.city) { newCity in
            if !newCity.isEmpty {
                locationText = newCity
            }
        }
    }
    
    private var isValid: Bool {
        guard let volume = Double(volumeText),
              let amount = Double(amountText),
              let odometer = Double(odometerText),
              !locationText.isEmpty else {
            return false
        }
        return volume > 0 && amount > 0 && odometer > 0
    }
}
