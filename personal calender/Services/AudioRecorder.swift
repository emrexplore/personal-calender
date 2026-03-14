import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionGranted = false
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private(set) var recordedAudioURL: URL?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
    }
    
    func startRecording() {
        guard permissionGranted else { return }
        
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            let filename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
            self.recordedAudioURL = filename
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            startTimer()
            
        } catch {
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
    }
    
    func discardRecording() {
        if isRecording {
            stopRecording()
        }
        if let url = recordedAudioURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Could not delete recording: \(error)")
            }
        }
        recordedAudioURL = nil
        recordingDuration = 0
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            self.recordingDuration = recorder.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
}
