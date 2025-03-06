import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcript: String = ""
    @Published var error: Error?
    @Published var isAuthorized = false
    @Published var parsedData: FillUpData?
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var hasTap = false
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                    self?.requestRecordPermission()
                case .denied:
                    self?.isAuthorized = false
                    self?.error = NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition permission denied"])
                case .restricted:
                    self?.isAuthorized = false
                    self?.error = NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition restricted on this device"])
                case .notDetermined:
                    self?.isAuthorized = false
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    private func requestRecordPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.error = NSError(domain: "SpeechRecognizer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                }
            }
        }
    }
    
    func startRecording() {
        // Reset any previous recording
        resetRecording()
        
        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = error
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.error = NSError(domain: "SpeechRecognizer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error
                self.stopRecording()
                return
            }
            
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
                self.parsedData = FillUpData.fromSpeechTranscript(self.transcript)
            }
        }
        
        // Configure the audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasTap = true
        
        // Start the audio engine
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = error
            resetRecording()
        }
    }
    
    func stopRecording() {
        if hasTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        
        // Try to deactivate the audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func resetRecording() {
        if hasTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""
        parsedData = nil
        error = nil
    }
} 