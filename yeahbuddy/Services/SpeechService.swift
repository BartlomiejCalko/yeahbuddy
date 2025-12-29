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
    case stopByUser // User manually stopped
    case resume // User resumed session
    
    // New Events
    case beforeLastRep // Triggered after counting the 2nd to last rep
    case twoMoreReps // Triggered 3rd from end (repsRemaining == 2)
    case tenSecondsLeftInRest // Triggered when rest timer = 10
    case nextSet // Triggered at start of new set (if not last)
    case lastSet // Triggered at start of last set
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
    
    @discardableResult
    func playEvent(_ event: WorkoutEvent) -> TimeInterval {
        // Stop any previous speech or sound to prevent overlap (unless chaining?)
        // For sequences, we might want to be careful.
        stopPlayback()
        
        switch event {
        case .start:
            let dur = playSoundFile(named: "start")
            if dur > 0 { return dur }
            speak("Let's do this! Yeah Buddy!", style: .hype)
            return 2.0
            
        case .resume:
            let dur = playSoundFile(named: "resume_workout")
            if dur > 0 { return dur }
            speak("Welcome back! Let's finish this.", style: .hype)
            return 2.5
            
        case .stopByUser:
            let dur = playSoundFile(named: "stop_workout_by_user")
            if dur > 0 { return dur }
            speak("Session paused.", style: .calm)
            return 1.5
            
        case .rep(let count):
            // 1. Try to play specific audio file for the number
            let dur = playSoundFile(named: "\(count)")
            if dur > 0 {
                // Success
            } else {
                speak("\(count)", style: .hype)
            }
            
            return dur > 0 ? dur : 1.0
            
        case .beforeLastRep:
            // "Zaraz po drugim od konca"
            let dur = playSoundFile(named: "before-last-one")
            if dur > 0 { return dur }
            speak("One more! You got this!", style: .hype)
            return 2.0
            
        case .twoMoreReps:
            let dur = playSoundFile(named: "two_more_reps")
            if dur > 0 { return dur }
            speak("Two more!", style: .hype)
            return 1.5
            
        case .tenSecondsLeftInRest:
            let dur = playSoundFile(named: "be_ready_next_set")
            if dur > 0 { return dur }
            speak("Get ready.", style: .calm)
            return 1.0
            
        case .nextSet:
            let dur = playSoundFile(named: "next_set")
            if dur > 0 { return dur }
            speak("Next Set.", style: .hype)
            return 1.5
            
        case .lastSet:
            let dur = playSoundFile(named: "last_set")
            if dur > 0 { return dur }
            speak("Last Set! Give it all!", style: .hype)
            return 2.5
            
        case .rest(let seconds):
            // Fallback if setComplete didn't handle it
            speak("Rest \(seconds) seconds.", style: .calm)
            return 2.0
            
        case .setComplete(let succeeded):
             if succeeded {
                 // user requested: set_complete.mp3 THEN rest.mp3
                 // This is async sequence. We return approximate.
                 playSequence(filenames: ["set_complete", "rest"])
                 return 3.0 // Approx
             } else {
                 let dur = playSoundFile(named: "failure")
                 if dur > 0 { return dur }
                 speak("Good try.", style: .calm)
                 return 1.5
             }
            
        case .finish:
            let dur = playSoundFile(named: "finish")
            if dur > 0 { return dur }
            speak("Workout Complete! Good job.", style: .hype)
            return 3.0
            
        case .lightweight:
             let dur = playSoundFile(named: "lightweight")
             if dur > 0 { return dur }
             speak("Light weight baby!", style: .hype)
             return 2.0
        }
    }
    
    // MARK: - Helpers
    
    // Simple sequencer to play file 1, then file 2
    private func playSequence(filenames: [String]) {
        guard !filenames.isEmpty else { return }
        var queue = filenames
        
        func playNext() {
            guard !queue.isEmpty else { return }
            let name = queue.removeFirst()
            
            let dur = playSoundFile(named: name)
            if dur > 0 {
                // If successful, wait for duration
                DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.2) {
                    playNext()
                }
            } else {
                // If file missing, skip immediately
                playNext()
            }
        }
        
        playNext()
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
    
    /// Returns duration if played, else 0
    private func playSoundFile(named filename: String) -> TimeInterval {
        // Try mp3, wav, m4a
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    return audioPlayer?.duration ?? 0
                } catch {
                    print("Failed to play sound \(filename).\(ext): \(error)")
                }
            }
        }
        return 0
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
