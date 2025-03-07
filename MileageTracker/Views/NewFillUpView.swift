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
    let onSave: (() -> Void)?
    
    // Form State
    @State private var date = Date()
    @State private var odometerText = ""
    @State private var litersText = ""
    @State private var amountText = ""
    @State private var location = ""
    @State private var description = ""
    
    // MARK: - Initialization
    init(store: MileageStore, prefillData: FillUpData? = nil, onSave: (() -> Void)? = nil) {
        self.store = store
        self.onSave = onSave
        if let data = prefillData {
            _odometerText = State(initialValue: data.odometer.map { String(format: "%.0f", $0) } ?? "")
            _litersText = State(initialValue: data.volume.map { String(format: "%.1f", $0) } ?? "")
            _amountText = State(initialValue: data.amount.map { String(format: "%.2f", $0) } ?? "")
            _location = State(initialValue: data.location)
            _fillUpData = State(initialValue: data)
        }
    }
    
    // MARK: - View
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    FillUpDetailsSection(
                        odometerText: $odometerText,
                        litersText: $litersText,
                        amountText: $amountText
                    )
                    
                    AdditionalDetailsSection(
                        date: $date,
                        location: $location,
                        description: $description,
                        locationManager: locationManager
                    )
                    
                    if let gst = calculateGST() {
                        TaxDetailsSection(gst: gst)
                    }
                }
                
                VStack {
                    Spacer()
                    Button(action: {
                        showingSpeechInput = true
                    }) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                            .background(Circle().fill(.white))
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("New Fillup")
            .navigationBarItems(
                leading: makeCancelButton(),
                trailing: makeSaveButton()
            )
            .sheet(isPresented: $showingSpeechInput) {
                SpeechInputView(
                    fillUpData: $fillUpData,
                    showManualEntry: false,
                    store: store
                )
            }
            .onChange(of: locationManager.city) { oldValue, newValue in
                if !newValue.isEmpty && location.isEmpty {
                    location = newValue
                }
            }
            .onChange(of: fillUpData) { oldValue, newValue in
                // Update form fields when speech input changes
                if let volume = newValue.volume {
                    litersText = String(format: "%.1f", volume)
                }
                if let amount = newValue.amount {
                    amountText = String(format: "%.2f", amount)
                }
                if !newValue.location.isEmpty {
                    location = newValue.location
                }
                if let odometer = newValue.odometer {
                    odometerText = String(format: "%.0f", odometer)
                }
            }
        }
    }
}

// MARK: - Form Sections
private struct FillUpDetailsSection: View {
    @Binding var odometerText: String
    @Binding var litersText: String
    @Binding var amountText: String
    
    var body: some View {
        Section("Fill-up Details") {
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
            
            HStack {
                Text("Volume")
                Spacer()
                TextField("L", text: $litersText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .onChange(of: litersText) { oldValue, newValue in
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
                    .onChange(of: amountText) { oldValue, newValue in
                        amountText = newValue.filter { "0123456789.".contains($0) }
                    }
            }
        }
    }
}

private struct AdditionalDetailsSection: View {
    @Binding var date: Date
    @Binding var location: String
    @Binding var description: String
    let locationManager: LocationManager
    
    var body: some View {
        Section("Additional Details") {
            DatePicker("Date", selection: $date, displayedComponents: [.date])
            
            HStack {
                Text("Location")
                Spacer()
                TextField("Enter location", text: $location)
                    .multilineTextAlignment(.trailing)
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "location.fill")
                }
            }
            
            TextField("Description (Optional)", text: $description)
        }
    }
}

private struct TaxDetailsSection: View {
    let gst: Double
    
    var body: some View {
        Section("Tax Details") {
            HStack {
                Text("GST (5%)")
                Spacer()
                Text(String(format: "$%.2f", gst))
            }
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
        onSave?()
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
