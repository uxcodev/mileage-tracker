import SwiftUI
import Speech

struct NewFillUpInputMethodView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: MileageStore
    @State private var showingManualEntry = false
    @State private var showingScanner = false
    @State private var isRecording = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    showingManualEntry = true
                }) {
                    Label("Manual Entry", systemImage: "keyboard")
                }
                
                Button(action: {
                    if speechRecognizer.isAuthorized {
                        speechRecognizer.startRecording()
                    }
                }) {
                    Label(speechRecognizer.isRecording ? "Stop Recording" : "Voice Input", 
                          systemImage: speechRecognizer.isRecording ? "stop.circle" : "mic")
                }
                .disabled(!speechRecognizer.isAuthorized)
                
                if speechRecognizer.isRecording {
                    Section("Current Input") {
                        Text(speechRecognizer.transcript)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let data = speechRecognizer.parsedData {
                    Section("Parsed Data") {
                        if let odometer = data.odometer {
                            Text("Odometer: \(Int(odometer)) km")
                        }
                        if let volume = data.volume {
                            Text("Volume: \(String(format: "%.1f", volume)) L")
                        }
                        if let amount = data.amount {
                            Text("Amount: $\(String(format: "%.2f", amount))")
                        }
                        if !data.location.isEmpty {
                            Text("Location: \(data.location)")
                        }
                        
                        if let odometer = data.odometer,
                           let volume = data.volume,
                           let amount = data.amount {
                            Button("Save") {
                                store.addFuelFillUp(
                                    volume: volume,
                                    amount: amount,
                                    location: data.location.isEmpty ? "Voice Entry" : data.location,
                                    odometer: odometer
                                )
                                speechRecognizer.stopRecording()
                                dismiss()
                            }
                        } else {
                            Text("Missing required information")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = speechRecognizer.error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Fill-up")
            .navigationBarItems(leading: Button("Cancel") {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                }
                dismiss()
            })
        }
        .sheet(isPresented: $showingManualEntry) {
            NewFillUpView(store: store)
        }
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerView(store: store)
        }
    }
} 