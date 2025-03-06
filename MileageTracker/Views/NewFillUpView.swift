import SwiftUI
import CoreLocation

struct NewFillUpView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: MileageStore
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var fillUpData = FillUpData()
    @State private var showingSpeechInput = false
    
    // Form State
    @State private var date = Date()
    @State private var odometerText = ""
    @State private var litersText = ""
    @State private var amountText = ""
    @State private var location = ""
    @State private var description = ""
    
    // MARK: - View
    var body: some View {
        NavigationView {
            FormContent(
                date: $date,
                odometerText: $odometerText,
                litersText: $litersText,
                amountText: $amountText,
                location: $location,
                description: $description,
                locationManager: locationManager,
                gst: calculateGST()
            )
            .navigationTitle("New Fill-up")
            .navigationBarItems(
                leading: makeCancelButton(),
                trailing: makeSaveButton()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    makeMicButton()
                }
            }
            .sheet(isPresented: $showingSpeechInput) {
                SpeechInputView(
                    fillUpData: $fillUpData
                )
            }
            .onChange(of: locationManager.city) { newCity in
                if !newCity.isEmpty {
                    location = newCity
                }
            }
            .onChange(of: fillUpData) { data in
                // Update form fields when speech input changes
                if let volume = data.volume {
                    litersText = String(format: "%.1f", volume)
                }
                if let amount = data.amount {
                    amountText = String(format: "%.2f", amount)
                }
                if !data.location.isEmpty {
                    location = data.location
                }
                if let odometer = data.odometer {
                    odometerText = String(format: "%.0f", odometer)
                }
            }
        }
    }
}

// MARK: - Private Views
private struct FormContent: View {
    @Binding var date: Date
    @Binding var odometerText: String
    @Binding var litersText: String
    @Binding var amountText: String
    @Binding var location: String
    @Binding var description: String
    let locationManager: LocationManager
    let gst: Double?
    
    var body: some View {
        Form {
            DateSection(date: $date)
            VehicleDetailsSection(odometerText: $odometerText)
            FillUpDetailsSection(litersText: $litersText, amountText: $amountText)
            LocationSection(location: $location, locationManager: locationManager)
            AdditionalInfoSection(description: $description)
            if let gst = gst {
                TaxDetailsSection(gst: gst)
            }
        }
    }
}

// MARK: - Form Sections
private struct DateSection: View {
    @Binding var date: Date
    
    var body: some View {
        Section("Date") {
            DatePicker("Date", selection: $date, displayedComponents: [.date])
        }
    }
}

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
                    .onChange(of: odometerText) { newValue in
                        odometerText = newValue.filter { "0123456789".contains($0) }
                    }
            }
        }
    }
}

private struct FillUpDetailsSection: View {
    @Binding var litersText: String
    @Binding var amountText: String
    
    var body: some View {
        Section("Fill-up Details") {
            HStack {
                Text("Volume")
                Spacer()
                TextField("L", text: $litersText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: litersText) { newValue in
                        litersText = newValue.filter { "0123456789.".contains($0) }
                    }
            }
            
            HStack {
                Text("Amount")
                Spacer()
                TextField("$", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: amountText) { newValue in
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
                TextField("Location", text: $location)
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "location.fill")
                }
            }
        }
    }
}

private struct AdditionalInfoSection: View {
    @Binding var description: String
    
    var body: some View {
        Section("Additional Information") {
            TextField("Description (Optional)", text: $description)
        }
    }
}

private struct TaxDetailsSection: View {
    let gst: Double
    
    var body: some View {
        Section("Tax Details") {
            Text("GST (5%): $\(String(format: "%.2f", gst))")
        }
    }
}

// MARK: - Helper Methods
extension NewFillUpView {
    private func makeCancelButton() -> some View {
        Button("Cancel") {
            dismiss()
        }
    }
    
    private func makeSaveButton() -> some View {
        Button("Save") {
            saveForm()
        }
        .disabled(!isValid)
    }
    
    private func makeMicButton() -> some View {
        Button(action: { showingSpeechInput = true }) {
            Image(systemName: "mic.fill")
        }
    }
    
    private func saveForm() {
        guard let volumeDouble = Double(litersText),
              let amountDouble = Double(amountText),
              let odometerDouble = Double(odometerText) else { return }
        
        store.addFuelFillUp(
            volume: volumeDouble,
            amount: amountDouble,
            location: location,
            odometer: odometerDouble
        )
        dismiss()
    }
    
    private var isValid: Bool {
        guard let odometer = Double(odometerText),
              let liters = Double(litersText),
              let amount = Double(amountText),
              !location.isEmpty else {
            return false
        }
        return odometer > 0 && liters > 0 && amount > 0
    }
    
    private func calculateGST() -> Double? {
        guard let amount = Double(amountText) else { return nil }
        return amount * 0.05
    }
}

#Preview {
    NavigationView {
        NewFillUpView(store: MileageStore())
            .onAppear {
                // Simulate location for preview
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // Simulate a delay and city update
                        let previewLocationManager = LocationManager()
                        previewLocationManager.city = "Preview City"
                    }
                }
            }
    }
}