import SwiftUI
import VisionKit
import Vision

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MileageStore
    @State private var scannedText: String = ""
    @State private var showingScanner = true
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showingScanner {
                    DocumentScannerView { result in
                        switch result {
                        case .success(let scan):
                            isProcessing = true
                            showingScanner = false
                            processScannedImages(scan.imageOfPage(at: 0))
                        case .failure(let error):
                            print("Scanning failed: \(error.localizedDescription)")
                            dismiss()
                        }
                    }
                } else {
                    VStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Processing receipt...")
                                .font(.headline)
                        } else {
                            Text("Scanned Text:")
                                .font(.headline)
                            ScrollView {
                                Text(scannedText)
                                    .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Scan Receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func processScannedImages(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                isProcessing = false
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                scannedText = text
                isProcessing = false
                parseReceiptText(text)
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    private func parseReceiptText(_ text: String) {
        // We'll implement the parsing logic in the next step
        // This will look for patterns like dollar amounts, liters, etc.
    }
} 