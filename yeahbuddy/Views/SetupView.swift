//
//  SetupView.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import SwiftUI

struct SetupView: View {
    @StateObject private var viewModel = WorkoutSessionViewModel()
    @State private var navigateToWorkout = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                YBGradients.mainBackground
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Image("logo-white-2")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 90)
                            .onLongPressGesture(minimumDuration: 2) {
                                hasCompletedOnboarding = false
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            }
                        Text("Lightweight Baby!")
                            .font(.headline)
                            .foregroundColor(YBColors.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Configuration Card
                    VStack(spacing: 24) {
                        configRow(label: "Target Reps", value: $viewModel.targetReps, range: 1...30, icon: "repeat")
                        Divider().background(Color.white.opacity(0.3))
                        configRow(label: "Target Sets", value: $viewModel.targetSets, range: 1...10, icon: "square.stack.3d.up.fill")
                        Divider().background(Color.white.opacity(0.3))
                        configRow(label: "Rest Time", value: $viewModel.restTime, range: 10...180, step: 10, icon: "timer")
                    }
                    .padding(24)
                    .glassCard()
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        if viewModel.hasSavedSession {
                            // Resume Button
                            Button(action: {
                                viewModel.restoreSession()
                                navigateToWorkout = true
                            }) {
                                HStack {
                                    Text("RESUME SESSION")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Image(systemName: "play.circle.fill")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(colors: [YBColors.neonGreen, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(30)
                                .shadow(color: YBColors.neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Start New Button (Secondary Style)
                            Button(action: {
                                viewModel.start()
                                navigateToWorkout = true
                            }) {
                                Text("Start New Workout")
                                    .font(.headline)
                                    .foregroundColor(YBColors.textSecondary)
                                    .padding()
                            }
                        } else {
                            // Standard Start Button
                            Button(action: {
                                viewModel.start()
                                navigateToWorkout = true
                            }) {
                                HStack {
                                    Text("START WORKOUT")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(colors: [YBColors.neonPink, YBColors.backgroundStart], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(30)
                                .shadow(color: YBColors.neonPink.opacity(0.5), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToWorkout) {
                WorkoutView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.checkForSavedSession()
            }
            .onChange(of: viewModel.workoutCompleted) { _, completed in
                if completed {
                    navigateToWorkout = false
                }
            }
        }
    }
    
    // Custom Glass Config Row
    private func configRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(YBColors.neonGreen)
                .frame(width: 30)
            
            Text(label)
                .font(.headline)
                .foregroundColor(YBColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= step
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(YBColors.textSecondary)
                }
                
                Text("\(value.wrappedValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(YBColors.textPrimary)
                    .frame(minWidth: 40)
                    .monospacedDigit()
                
                Button(action: {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += step
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(YBColors.textSecondary)
                }
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
