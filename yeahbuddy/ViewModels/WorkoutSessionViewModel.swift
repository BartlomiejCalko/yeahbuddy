//
//  WorkoutSessionViewModel.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import Foundation
import SwiftUI
import Combine

class WorkoutSessionViewModel: ObservableObject {
    // Configuration
    @Published var targetReps: Int = 10
    @Published var targetSets: Int = 3
    @Published var restTime: Int = 60
    
    // Live State
    @Published var currentSet: Int = 1
    @Published var currentRep: Int = 0
    // We track reps remaining for the current set
    @Published var repsRemaining: Int = 10
    
    @Published var isResting: Bool = false
    @Published var timeRemaining: Int = 0
    @Published var isWorkoutActive: Bool = false
    
    // Dependencies
    private let speechService = SpeechService()
    @Published var audioInputService = AudioInputService()
    
    // Timer & Subs
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    // Debounce
    private var lastRepTime: Date = Date.distantPast
    private let minRepDuration: TimeInterval = 1.3 // Minimum seconds between reps
    
    init() {
        // Subscribe to audio events
        audioInputService.soundDetected
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.completeRep()
            }
            .store(in: &cancellables)
    }
    
    func start() {
        resetState()
        isWorkoutActive = true
        // Event-based audio
        speechService.playEvent(.start)
        
        audioInputService.requestPermission()
        
        // DELAY: Wait 3 seconds for the "Start Sound" to finish before listening.
        // This prevents the app from hearing itself and counting a phantom rep.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isWorkoutActive else { return }
            self.audioInputService.startMonitoring()
        }
    }
    
    func stop() {
        isWorkoutActive = false
        stopTimer()
        audioInputService.stopMonitoring()
        speechService.playEvent(.finish) // Or stop event, but user usually stops at finish
    }
    
    func completeRep() {
        guard isWorkoutActive, !isResting else { return }
        
        // Prevent over-counting (Premium Feel: Strict adherence to plan)
        guard repsRemaining > 0 else { return }
        
        // DEBOUNCE: Check if enough time has passed since last rep
        let now = Date()
        guard now.timeIntervalSince(lastRepTime) > minRepDuration else {
            print("Rep Ignored (Debounce active)")
            return
        }
        
        lastRepTime = now
        currentRep += 1
        repsRemaining = max(0, targetReps - currentRep)
        
        // Use event for Rep counting
        // Note: SpeechService handles logic (3rd rep = lightweight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, self.isWorkoutActive else { return }
            self.speechService.playEvent(.rep(count: self.currentRep))
        }
        
        // Logic for End of Set
        if repsRemaining == 0 {
            // STOP MONITORING IMMEDIATELY to prevent phantom "11th" rep
            audioInputService.stopMonitoring()
            
            // DELAY: Wait for audio to finish before transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.finishSet()
            }
        }
    }
    
    private func finishSet() {
        if currentSet >= targetSets {
            finishWorkout()
        } else {
            startRest()
        }
    }
    
    private func startRest() {
        isResting = true
        timeRemaining = restTime
        audioInputService.stopMonitoring()
        speechService.playEvent(.rest(seconds: restTime))
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickRest()
            }
    }
    
    private func tickRest() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            endRest()
        }
    }
    
    private func endRest() {
        stopTimer()
        isResting = false
        currentSet += 1
        resetRepsForSet()
        audioInputService.startMonitoring()
        // Announce new set
        speechService.playEvent(.start) // Reuse start sound for set start, or could be separate
    }
    
    private func finishWorkout() {
        isWorkoutActive = false
        audioInputService.stopMonitoring()
        speechService.playEvent(.finish)
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func resetState() {
        currentSet = 1
        resetRepsForSet()
        isResting = false
    }
    
    private func resetRepsForSet() {
        currentRep = 0
        repsRemaining = targetReps
    }
}
