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
        
        currentRep += 1
        repsRemaining = max(0, targetReps - currentRep)
        
        // DELAY: Wait 0.6s so we don't speak over the user's grunt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, self.isWorkoutActive else { return }
            // Use event for Rep counting (handles custom sounds internally)
            self.speechService.playEvent(.rep(count: self.currentRep))
        }
        
        // Motivation engine logic is largely replaced by custom sounds,
        // but we can keep it for specific milestones if we wanted to mix them.
        // For now, let's trust the playEvent(.rep) logic which handles "Lightweight" quotes randomly.
        
        if repsRemaining == 0 {
            finishSet()
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
