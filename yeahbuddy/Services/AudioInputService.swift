//
//  AudioInputService.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import Foundation

import Foundation
import AVFoundation
import Combine
import SwiftUI

enum AudioPreset: String, CaseIterable {
    case home = "Home"
    case gym = "Gym"
    case loud = "Loud"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gym: return "dumbbell.fill"
        case .loud: return "speaker.wave.3.fill"
        }
    }
    
    var baseThreshold: Float {
        switch self {
        case .home: return -30.0 // Adjusted: More sensitive
        case .gym: return -25.0  // Adjusted based on user feedback
        case .loud: return -15.0  // Adjusted
        }
    }
    
    var baseGain: Float {
        switch self {
        case .home: return 10.0   // Higher boost
        case .gym: return 5.0    // Mild boost
        case .loud: return 0.0
        }
    }
    
    var description: String {
        switch self {
        case .home: return "Best for quiet rooms. Detects breathing & soft grunts."
        case .gym: return "Best for standard gym noise. Filters background music."
        case .loud: return "Best for noisy areas. You must be close to the phone."
        }
    }
}

class AudioInputService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    // Configurable Settings (Preset Driven)
    @Published var activePreset: AudioPreset = .gym {
        didSet { updateSettings() }
    }
    
    // Fine Tune: -5 (Easier/More Sensitive) to +5 (Harder/Less Sensitive)
    // Actually simplicity: Let's match slider direction.
    // Slide Left (Easier) -> Lower Threshold. Slide Right (Harder) -> Higher Threshold.
    // Let's standardize: 0 is default. Range -5 to +5.
    @Published var sensitivityAdjustment: Float = 0.0 {
        didSet { updateSettings() }
    }
    
    // Internal Effective Values
    @Published private(set) var threshold: Float = -15.0
    @Published private(set) var inputGain: Float = 0.0 
    
    private func updateSettings() {
        self.inputGain = activePreset.baseGain
        // Adjustment: Negative adjustment = Lower Threshold (More Sensitive).
        // e.g. Base -15. Adj -5 => -20 (More Sensitive).
        self.threshold = activePreset.baseThreshold + sensitivityAdjustment
    }
    
    // Hysteresis Settings
    // The level must drop below checkThreshold - resetHysteresis to "Reset" the trigger.
    private let resetHysteresis: Float = 10.0 
    
    // State
    @Published var currentDecibels: Float = -160.0
    
    // "Is the user currently making a sound that has already triggered a rep?"
    // If true, we are waiting for silence (dB < threshold - hysteresis).
    // If false, we are waiting for a loud sound (dB > threshold).
    private var isTriggerActive: Bool = false
    
    // Outputs
    let soundDetected = PassthroughSubject<Void, Never>()
    
    // Permission State
    @Published var permissionGranted = false
    
    init() {
        setupAudioSession()
        checkPermissionStatus()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Using .default mode is better for standard mic input and noise suppression.
            // Removing overrideOutputAudioPort(.speaker) allows Headphones to work automatically.
            try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session Setup Error: \(error)")
        }
    }
    
    func checkPermissionStatus() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                DispatchQueue.main.async { self.permissionGranted = true }
            case .denied:
                print("Microphone permission previously denied.")
                DispatchQueue.main.async { self.permissionGranted = false }
            case .undetermined:
                print("Microphone permission undetermined.")
                DispatchQueue.main.async { self.permissionGranted = false }
            @unknown default:
                break
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                DispatchQueue.main.async { self.permissionGranted = true }
            case .denied:
                print("Microphone permission previously denied.")
                DispatchQueue.main.async { self.permissionGranted = false }
            case .undetermined:
                print("Microphone permission undetermined.")
                DispatchQueue.main.async { self.permissionGranted = false }
            @unknown default:
                break
            }
        }
    }

    func requestPermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                self.permissionGranted = true
                setupEngine()
            case .denied:
                print("Permission denied. User must enable in Settings.")
                self.permissionGranted = false
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permissionGranted = granted
                        if granted {
                            self?.setupEngine()
                        }
                    }
                }
            @unknown default:
                break
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                self.permissionGranted = true
                setupEngine()
            case .denied:
                print("Permission denied. User must enable in Settings.")
                self.permissionGranted = false
            case .undetermined:
                session.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permissionGranted = granted
                        if granted {
                            self?.setupEngine()
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    private func setupEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        let inputFormat = inputNode?.outputFormat(forBus: 0)
        
        // Remove tap if exists
        inputNode?.removeTap(onBus: 0)
        
        // Install tap on input node
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
            self?.processBuffer(buffer)
        }
    }
    
    func startMonitoring() {
        if audioEngine == nil || audioEngine?.isRunning == false {
             // Re-setup if needed
             if audioEngine == nil { setupEngine() }
             
             do {
                 try audioEngine?.start()
                 // Reset trigger state on start
                 isTriggerActive = false 
             } catch {
                 print("Audio Engine Start Error: \(error)")
             }
        }
    }
    
    func stopMonitoring() {
        audioEngine?.stop()
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        // Calculate RMS
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        
        // Convert to dB
        let rawDb = 20 * log10(rms)
        
        // Publish updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Apply software gain
            let adjustedDb = rawDb + self.inputGain
            
            // Clamp
            self.currentDecibels = adjustedDb.isFinite ? adjustedDb : -160.0
            
            self.checkForSound(decibels: self.currentDecibels)
        }
    }
    
    private func checkForSound(decibels: Float) {
        if isTriggerActive {
            // We are waiting for the sound to finish (drop below reset threshold).
            // This PREVENTS machine-gun firing while the user is still screaming "YEAAAH".
            let resetThreshold = threshold - resetHysteresis
            if decibels < resetThreshold {
                isTriggerActive = false // Reset. Ready for next rep.
                print("Audio Trigger Reset (Level dropped below \(resetThreshold))")
            }
        } else {
            // We are listening for a NEW sound.
            if decibels > threshold {
                 // FIRE!
                 isTriggerActive = true
                 soundDetected.send()
                 print("Audio Trigger FIRED (Level > \(threshold))")
            }
        }
    }
}
