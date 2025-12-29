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

class AudioInputService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    // Configurable Settings
    @Published var threshold: Float = -10.0 // dB (Safer default to avoid phantom reps)
    private let cooldown: TimeInterval = 0.35 // 350ms
    
    // State
    @Published var currentDecibels: Float = -160.0
    private var lastDetectionTime: Date = Date.distantPast
    
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
            // Use .videoRecording mode, which implies "Loud Speaker + Mic" usage (Camcorder style).
            // .measurement often disables gain, leading to low volume.
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
            try session.overrideOutputAudioPort(.speaker)
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
        if audioEngine == nil {
            setupEngine()
        }
        
        do {
            if let engine = audioEngine, !engine.isRunning {
                try engine.start()
            }
        } catch {
            print("Audio Engine Start Error: \(error)")
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
        let avgPower = 20 * log10(rms)
        
        // Publish updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clamp roughly to -160 (silence) to 0 (max)
            self.currentDecibels = avgPower.isFinite ? avgPower : -160.0
            
            self.checkForSound(decibels: self.currentDecibels)
        }
    }
    
    private func checkForSound(decibels: Float) {
        let now = Date()
        if decibels > threshold && now.timeIntervalSince(lastDetectionTime) > cooldown {
            // Detected!
            lastDetectionTime = now
            soundDetected.send()
        }
    }
}
