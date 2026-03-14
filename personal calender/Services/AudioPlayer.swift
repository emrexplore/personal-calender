import Foundation
import AVFoundation
import Combine

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var playbackProgress: Double = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func playAudio(from url: URL) {
        let session = AVAudioSession.sharedInstance()
        do {
            // overrideOutputAudioPort set in order to play sound via speaker instead of earpiece
            try session.setCategory(.playback, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            startTimer()
        } catch {
            print("Oynatma hatası: \(error)")
        }
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        playbackProgress = 0.0
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playbackProgress = 0.0
        stopTimer()
    }
}
