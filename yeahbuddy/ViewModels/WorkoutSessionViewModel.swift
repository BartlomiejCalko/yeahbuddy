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
    @Published var workoutCompleted: Bool = false
    @Published var isPaused: Bool = false
    
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
        workoutCompleted = false
        isPaused = false
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
        // This old stop method is effectively "Quit" but with saving. 
        // We will repurpose logic for the new quitWorkout.
        // Keeping this for backward compatibility if needed, but for now:
        quitWorkout()
    }
    
    func togglePause() {
        if isPaused {
            // RESUME
            isPaused = false
            
            if isResting {
                startRest(resume: true)
            } else {
                audioInputService.startMonitoring()
            }
            
            // Interaction Sound
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            speechService.playEvent(.resume)
            
        } else {
            // PAUSE
            isPaused = true
            stopTimer()
            audioInputService.stopMonitoring()
            
            // Interaction Sound
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    func quitWorkout() {
        isWorkoutActive = false
        isPaused = false
        stopTimer()
        audioInputService.stopMonitoring()
        clearSession() // Ensure we don't resume this later
        
        // Interaction Sound
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Trigger dismissal
        workoutCompleted = true
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
        // Note: SpeechService handles specific file playback for numbers.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, self.isWorkoutActive else { return }
            self.speechService.playEvent(.rep(count: self.currentRep))
            
            // Exclusive Priority Logic for Secondary Sounds (Motivation / Warnings)
            // Delay slightly to let the number finish.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if self.repsRemaining == 1 {
                    // "before-last-one.mp3" (Overrides Lightweight)
                    self.speechService.playEvent(.beforeLastRep)
                } else if self.repsRemaining == 2 {
                    // "two_more_reps.mp3" (Overrides Lightweight if it was a multiple of 3)
                     self.speechService.playEvent(.twoMoreReps)
                } else if self.currentRep % 3 == 0 {
                    // Standard "lightweight.mp3"
                     self.speechService.playEvent(.lightweight)
                }
            }
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
            // Trigger "set_complete" + "rest" sequence
            speechService.playEvent(.setComplete(succeeded: true))
            startRest()
        }
    }
    
    private func startRest(resume: Bool = false) {
        if !resume {
            isResting = true
            timeRemaining = restTime
            audioInputService.stopMonitoring()
            // Removed direct .rest call here, as .setComplete handles the sequence
        }
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickRest()
            }
    }
    
    private func tickRest() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            
            // "gdy zostanie ostatnie 10 sekund odtworz plik be_ready_next_set.mp3"
            if timeRemaining == 10 {
                speechService.playEvent(.tenSecondsLeftInRest)
            }
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
        
        // "po zakonczeniu rest count- odtworz z delay 0.3 plik next_set.mp3 lub last_set.mp3"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.isWorkoutActive else { return }
            
            if self.currentSet == self.targetSets {
                 self.speechService.playEvent(.lastSet)
            } else {
                 self.speechService.playEvent(.nextSet)
            }
        }
    }
    
    private func finishWorkout() {
        isWorkoutActive = false
        audioInputService.stopMonitoring()
        clearSession()
        
        // Play finish sound and get duration
        let duration = speechService.playEvent(.finish)
        
        // Signal view to dismiss after audio finishes + buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) { [weak self] in
             self?.workoutCompleted = true
        }
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
    
    // MARK: - Persistence
    @Published var hasSavedSession: Bool = false
    private let storageKey = "savedWorkoutState"
    
    func checkForSavedSession() {
        hasSavedSession = UserDefaults.standard.data(forKey: storageKey) != nil
    }
    
    func saveSession() {
        let state = WorkoutSessionState(
            targetReps: targetReps,
            targetSets: targetSets,
            restTime: restTime,
            currentSet: currentSet,
            currentRep: currentRep,
            repsRemaining: repsRemaining,
            isResting: isResting,
            timeRemaining: timeRemaining
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
            checkForSavedSession()
            print("Session Saved")
        }
    }
    
    func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(WorkoutSessionState.self, from: data) else { return }
        
        // Restore Config
        self.targetReps = state.targetReps
        self.targetSets = state.targetSets
        self.restTime = state.restTime
        
        // Restore Progress
        self.currentSet = state.currentSet
        self.currentRep = state.currentRep
        self.repsRemaining = state.repsRemaining
        self.isResting = state.isResting
        self.timeRemaining = state.timeRemaining
        
        // Resume Logic
        self.isWorkoutActive = true
        self.workoutCompleted = false
        
        // If we were resting, resume the timer
        if isResting {
            startRest(resume: true)
        } else {
             // If we were active, just start monitoring again
             // Wait briefly for UI transition
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                 self?.audioInputService.startMonitoring()
             }
        }
        
        // Delay audio for smoother UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.speechService.playEvent(.resume) // "resume_workout.mp3"
        }
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        checkForSavedSession()
    }
}

struct WorkoutSessionState: Codable {
    let targetReps: Int
    let targetSets: Int
    let restTime: Int
    let currentSet: Int
    let currentRep: Int
    let repsRemaining: Int
    let isResting: Bool
    let timeRemaining: Int
}
