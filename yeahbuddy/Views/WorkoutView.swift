//
//  WorkoutView.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import SwiftUI

struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            YBGradients.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header - Status Pill
                HStack {
                    Spacer()
                    if viewModel.isResting {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                            Text("RESTING")
                        }
                        .font(.title2.bold())
                        .foregroundColor(YBColors.neonGreen)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                            Text("WORKOUT")
                        }
                        .font(.title2.bold())
                        .foregroundColor(YBColors.neonPink)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                    }
                    Spacer()
                }
                .padding(.top, 40)
                
                // Stats Grid
                HStack(spacing: 16) {
                    // Left Column
                    VStack(spacing: 16) {
                        statCard(title: "SET", value: "\(viewModel.currentSet) / \(viewModel.targetSets)", icon: "square.stack.3d.up")
                        if !viewModel.isResting {
                            statCard(title: "DONE", value: "\(viewModel.currentRep)", icon: "checkmark.circle")
                        } else {
                           statCard(title: "NEXT SET", value: "\(viewModel.currentSet + 1)", icon: "arrow.forward.circle")
                        }
                    }
                    
                    // Right Column (Large)
                    VStack {
                        if viewModel.isResting {
                            Spacer()
                            Text("\(viewModel.timeRemaining)")
                                .font(.system(size: 80, weight: .heavy, design: .rounded))
                                .foregroundColor(YBColors.neonGreen)
                                .shadow(color: YBColors.neonGreen.opacity(0.5), radius: 20)
                            Text("SECONDS")
                                .font(.caption.bold())
                                .foregroundColor(YBColors.textSecondary)
                            Spacer()
                        } else {
                            Spacer()
                            Text("\(viewModel.repsRemaining)")
                                .font(.system(size: 100, weight: .heavy, design: .rounded))
                                .foregroundColor(YBColors.textPrimary)
                            Text("TO GO")
                                .font(.headline.bold())
                                .foregroundColor(YBColors.textSecondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassCard()
                }
                .frame(height: 220)
                .padding(.horizontal)
                
                Spacer()
                
                // Voice Control Section
                if !viewModel.isResting {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(YBColors.neonPink)
                            Text("VOICE TRIGGER")
                                .font(.headline)
                                .foregroundColor(YBColors.textPrimary)
                            Spacer()
                        }
                        
                        // Visualizer
                        AudioVisualizerBar(currentDecibels: viewModel.audioInputService.currentDecibels, threshold: viewModel.audioInputService.threshold)
                            .padding(.vertical, 8)
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        // Preset Picker
                        Picker("Scenario", selection: $viewModel.audioInputService.activePreset) {
                            ForEach(AudioPreset.allCases, id: \.self) { preset in
                                Label(preset.rawValue, systemImage: preset.icon).tag(preset)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark) // Force dark appearance for picker
                        
                        Text(viewModel.audioInputService.activePreset.description)
                            .font(.caption2)
                            .foregroundColor(YBColors.textSecondary)
                        
                        // Fine Tune
                        HStack {
                            Image(systemName: "minus").foregroundColor(YBColors.textSecondary)
                            Slider(value: $viewModel.audioInputService.sensitivityAdjustment, in: -10...10, step: 0.5)
                                .accentColor(YBColors.neonPink)
                            Image(systemName: "plus").foregroundColor(YBColors.textSecondary)
                        }
                        
                        HStack {
                            Text("Fine Tune")
                                .font(.caption2)
                                .foregroundColor(YBColors.textSecondary)
                            Spacer()
                            Text(viewModel.audioInputService.sensitivityAdjustment == 0 ? "Default" : String(format: "%+.1f dB", viewModel.audioInputService.sensitivityAdjustment))
                                .font(.caption.bold())
                                .foregroundColor(YBColors.neonGreen)
                        }
                    }
                    .padding(20)
                    .glassCard()
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Stop Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.stop()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("STOP SESSION")
                        .font(.headline.bold())
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
    
    // Helper Stat Card
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(YBColors.neonPink)
                Spacer()
            }
            Spacer()
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(YBColors.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(YBColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

struct AudioVisualizerBar: View {
    var currentDecibels: Float
    var threshold: Float
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Calculations
                let minDb: Float = -60
                let maxDb: Float = 5
                let range = maxDb - minDb
                
                // Threshold Line
                let threshRatio = (threshold - minDb) / range
                let threshNormalized = CGFloat(max(0, min(1, threshRatio)))
                
                // Current Level
                let levelRatio = (currentDecibels - minDb) / range
                let levelNormalized = CGFloat(max(0, min(1, levelRatio)))
                
                // Fill (Neon Gradient)
                Capsule()
                    .fill(
                        LinearGradient(colors: [YBColors.neonGreen, YBColors.backgroundEnd], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: levelNormalized * geo.size.width, height: 8)
                    .animation(.linear(duration: 0.1), value: currentDecibels)
                    .shadow(color: YBColors.neonGreen.opacity(0.8), radius: 5)
                
                // Marker
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 16)
                    .offset(x: threshNormalized * geo.size.width)
                    .shadow(color: .white, radius: 2)
            }
        }
        .frame(height: 16)
    }
}
