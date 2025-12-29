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
        VStack(spacing: 40) {
            // Header
            HStack {
                Spacer()
                if viewModel.isResting {
                    Text("RESTING")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.green)
                } else {
                    Text("WORKOUT")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Stats Grid
            VStack(spacing: 30) {
                statRow(title: "Current Set", value: "\(viewModel.currentSet) / \(viewModel.targetSets)")
                
                if viewModel.isResting {
                    statRow(title: "Time Remaining", value: "\(viewModel.timeRemaining)s", isHighlighted: true)
                } else {
                    statRow(title: "Reps Done", value: "\(viewModel.currentRep)")
                    statRow(title: "Reps Remaining", value: "\(viewModel.repsRemaining)", isHighlighted: true)
                }
            }
            .padding()
            
            Spacer()
            
            // Main Action / Stop
            VStack(spacing: 20) {
                
                // Debug / Calibration Section
                if !viewModel.isResting {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Microphone Calibration")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        // DB Meter
                        HStack {
                            Text("Level:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(viewModel.audioInputService.currentDecibels > viewModel.audioInputService.threshold ? Color.green : Color.blue)
                                        .frame(width: CGFloat(max(0, min(1, (viewModel.audioInputService.currentDecibels + 60) / 60))) * geo.size.width, height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(String(format: "%.1f dB", viewModel.audioInputService.currentDecibels))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        // Threshold Slider
                        HStack {
                            Text("Threshold:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.audioInputService.threshold, in: -90...0)
                            Text(String(format: "%.1f", viewModel.audioInputService.threshold))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        if !viewModel.audioInputService.permissionGranted {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Microphone permission required!")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.stop()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("STOP")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func statRow(title: String, value: String, isHighlighted: Bool = false) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(isHighlighted ? .blue : .primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}
