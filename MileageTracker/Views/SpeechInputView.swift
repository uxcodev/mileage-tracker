import SwiftUI
import Speech

struct SpeechInputView: View {
    @Binding var fillUpData: FillUpData
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Example formats:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• \"154,000 km 54 L $80\"")
                Text("• \"154000 kilometers 54 liters $80\"")
                Text("• \"in Vancouver 154000 km 54 L $80\"")
                Text("(Location will be used automatically if not specified)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if speechRecognizer.transcript.isEmpty {
                Text("Tap to start recording")
                    .foregroundColor(.secondary)
            } else {
                Text(speechRecognizer.transcript)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1)))
            }
            
            Button(action: {
                Task { @MainActor in
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        if let parsedData = speechRecognizer.parsedData {
                            fillUpData = parsedData
                            dismiss()
                        }
                    } else {
                        speechRecognizer.startRecording()
                    }
                }
            }) {
                Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
            }
            .disabled(!speechRecognizer.isAuthorized)
        }
        .padding()
        .onAppear {
            locationManager.requestLocation()
        }
    }
}