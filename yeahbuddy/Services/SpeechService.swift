//
//  SpeechService.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import Foundation
import AVFoundation

enum VoiceStyle {
    case calm
    case hype
}

enum WorkoutEvent {
    case start
    case rep(count: Int)
    case rest(seconds: Int)
    case setComplete(succeeded: Bool)
    case finish
    case lightweight // Special Coleman quote
}

class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?
    private var audioPlayer: AVAudioPlayer? // For custom sound files
    
    init() {
        // Configure audio session
        do {
            // Must use .playAndRecord to coexist with AudioInputService. Use .videoRecording for loud output.
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        findBestVoice()
    }
    
    // MARK: - Event Handling
    
    // MARK: - Event Handling
    
    func playEvent(_ event: WorkoutEvent) {
        // Stop any previous speech or sound to prevent overlap
        stopPlayback()
        
        switch event {
        case .start:
            if playSoundFile(named: "start") { return }
            speak("Let's do this! Yeah Buddy!", style: .hype)
            
        case .rep(let count):
            // Always speak the count first
            speak("\(count)", style: .hype)
            
            // Every 3rd rep (3, 6, 9...), play "Lightweight" AFTER the count.
            if count % 3 == 0 {
                // Delay to let "Three" finish (approx 0.5s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    // We check if we are still safe to play (rudimentary check, 
                    // relying on the next playEvent to kill this if it's too late)
                    _ = self?.playSoundFile(named: "lightweight")
                }
            }
            
        case .rest(let seconds):
            speak("Rest \(seconds) seconds.", style: .calm)
            
        case .setComplete:
            if playSoundFile(named: "set_complete") { return }
            speak("Set done. Breathe.", style: .calm)
            
        case .finish:
            if playSoundFile(named: "finish") { return }
            speak("Workout Complete! Good job.", style: .hype)
            
        case .lightweight:
             if playSoundFile(named: "lightweight") { return }
             speak("Light weight baby!", style: .hype)
        }
    }
    
    private func stopPlayback() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
    }
    
    // MARK: - Audio File Playback
    
    /// Returns true if file was found and played
    private func playSoundFile(named filename: String) -> Bool {
        // Try mp3, wav, m4a
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    return true
                } catch {
                    print("Failed to play sound \(filename).\(ext): \(error)")
                }
            }
        }
        return false
    }

    // MARK: - TTS Logic
    
    private func findBestVoice() {
        // Priority List of Identifiers (High Quality)
        let preferredIdentifiers = [
            "com.apple.speech.voice.Alex",            // Mac/iOS Premium
            "com.apple.ttsbundle.siri_male_en-US_compact", // Siri Male
            "com.apple.speech.voice.Fred"             // Classic Male
        ]
        
        for id in preferredIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                selectedVoice = voice
                return
            }
        }
        
        // General Search: English + Male + Enhanced (Best quality)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // 1. English (Any region) + Male + Enhanced
        if let enhancedMale = voices.first(where: { $0.language.starts(with: "en") && $0.gender == .male && $0.quality == .enhanced }) {
            selectedVoice = enhancedMale
            return
        }
        
        // 2. English (Any region) + Male (Standard)
        if let standardMale = voices.first(where: { $0.language.starts(with: "en") && $0.gender == .male }) {
            selectedVoice = standardMale
            return
        }
        
        // 3. Fallback: Any Enhanced English voice
        if let enhancedAny = voices.first(where: { $0.language.starts(with: "en") && $0.quality == .enhanced }) {
            selectedVoice = enhancedAny
            return
        }
        
        // 4. Last Resort
        selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
    }
    
    func speak(_ text: String, style: VoiceStyle = .hype) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        
        switch style {
        case .calm:
            utterance.rate = 0.45
            utterance.pitchMultiplier = 0.95
            utterance.volume = 0.9
        case .hype:
            utterance.rate = 0.50             // Normalized rate
            utterance.pitchMultiplier = 1.05  // Reduced from 1.15 to avoid "chipmunk/weird" artifact
            utterance.volume = 1.0
        }
        
        synthesizer.speak(utterance)
    }
}
