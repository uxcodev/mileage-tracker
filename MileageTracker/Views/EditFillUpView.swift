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
    
    var body: some View {
        Form {
            VehicleDetailsSection(odometerText: $odometerText)
            FillUpDetailsSection(volumeText: $volumeText, amountText: $amountText)
            LocationSection(location: $locationText, locationManager: locationManager)
            if let price = pricePerLiter {
                CalculatedValuesSection(
                    pricePerLiter: price,
                    consumptionData: consumptionData
                )
            }
            DeleteSection(showingDeleteAlert: $showingDeleteAlert)
        }
        .navigationTitle("Edit Fillup")
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
        .alert("Delete Fillup", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.deleteFillUp(fillUp)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this fillup? This action cannot be undone.")
        }
        .onChange(of: fillUp) { oldValue, newValue in
            // Update form fields when fillUp changes
            volumeText = String(format: "%.1f", newValue.volume)
            amountText = String(format: "%.2f", newValue.amount)
            locationText = newValue.location
            odometerText = String(format: "%.0f", newValue.odometer)
        }
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

// MARK: - Form Sections
private struct VehicleDetailsSection: View {
    @Binding var odometerText: String
    
    var body: some View {
        Section("Vehicle Details") {
            HStack {
                Text("Odometer")
                Spacer()
                TextField("km", text: $odometerText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: odometerText) { oldValue, newValue in
                        odometerText = newValue.filter { "0123456789".contains($0) }
                    }
            }
        }
    }
}

private struct FillUpDetailsSection: View {
    @Binding var volumeText: String
    @Binding var amountText: String
    
    var body: some View {
        Section("Fillup Details") {
            HStack {
                Text("Volume")
                Spacer()
                TextField("L", text: $volumeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: volumeText) { oldValue, newValue in
                        volumeText = newValue.filter { "0123456789.".contains($0) }
                    }
            }
            
            HStack {
                Text("Amount")
                Spacer()
                TextField("$", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: amountText) { oldValue, newValue in
                        amountText = newValue.filter { "0123456789.".contains($0) }
                    }
            }
        }
    }
}

private struct LocationSection: View {
    @Binding var location: String
    let locationManager: LocationManager
    
    var body: some View {
        Section("Location") {
            HStack {
                Text("Location")
                Spacer()
                TextField("Enter location", text: $location)
                    .multilineTextAlignment(.trailing)
                Button(action: {
                    locationManager.requestLocation()
                    // Only update location when button is tapped
                    if !locationManager.city.isEmpty {
                        location = locationManager.city
                    }
                }) {
                    Image(systemName: "location.fill")
                }
            }
        }
    }
}

private struct CalculatedValuesSection: View {
    let pricePerLiter: Double
    let consumptionData: (distance: Double, consumption: Double)?
    
    var body: some View {
        Section("Calculated Values") {
            HStack {
                Text("Price per Liter")
                Spacer()
                Text(pricePerLiter, format: .currency(code: "CAD"))
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
    }
}

private struct DeleteSection: View {
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Fillup")
                }
            }
        }
    }
}
