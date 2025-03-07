import SwiftUI
import Speech

struct SpeechInputView: View {
    @Binding var fillUpData: FillUpData
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var showingManualEntry = false
    @State private var isRecording = false
    @State private var showingFillUpView = false
    let showManualEntry: Bool
    let store: MileageStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Try saying something like:")
                    .font(.headline)
                
                Text("\"47.3 litres, 77 dollars, 150,000 kilometers in Vancouver\"")
                    .font(.body)
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
                
                Text("(Litres and location are optional)")
                    .font(.subheadline)
                
                
                if !speechRecognizer.transcript.isEmpty {
                    Text("Current Input:")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(speechRecognizer.transcript)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1)))
                }
                
                Spacer()
                
                if showManualEntry {
                    Button("Manual Entry") {
                        showingManualEntry = true
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom)
                }
                
                Button(action: {
                    Task { @MainActor in
                        if isRecording {
                            speechRecognizer.stopRecording()
                            if let parsedData = speechRecognizer.parsedData {
                                fillUpData = parsedData
                                showingFillUpView = true
                            }
                        } else {
                            speechRecognizer.startRecording()
                        }
                        isRecording.toggle()
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(isRecording ? .red : .blue)
                        .background(Circle().fill(.white))
                }
                .padding(.bottom, 16)
            }
            .padding()
            .navigationTitle("New Fillup")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .sheet(isPresented: $showingManualEntry) {
                NewFillUpView(store: store, onSave: { dismiss() })
            }
            .sheet(isPresented: $showingFillUpView) {
                NewFillUpView(store: store, prefillData: speechRecognizer.parsedData, onSave: { dismiss() })
            }
        }
    }
}