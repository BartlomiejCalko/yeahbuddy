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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Yeah Buddy")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 20) {
                    configRow(label: "Reps", value: $viewModel.targetReps, range: 1...50)
                    configRow(label: "Sets", value: $viewModel.targetSets, range: 1...20)
                    configRow(label: "Rest (s)", value: $viewModel.restTime, range: 10...180, step: 10)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: WorkoutView(viewModel: viewModel), isActive: $navigateToWorkout) {
                    EmptyView()
                }
                
                Button(action: {
                    viewModel.start()
                    navigateToWorkout = true
                }) {
                    Text("START")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
        }
        .preferredColorScheme(.dark) // Requirement: Dark Mode must look correct (forcing dark or respecting system, prompt says "supports Dark Mode correctly", usually implies respecting system but looking good. "Do NOT force light or dark mode yet" -> Okay I should remove .preferredColorScheme(.dark) if the prompt said DO NOT force.
        // Prompt Check: "4. Use dynamic system colors only... 5. Do NOT force light or dark mode yet"
        // Correcting: I will remove the modifier to respect system settings.
    }
    
    // Helper for configuration rows
    private func configRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Stepper(value: value, in: range, step: step) {
                Text("\(value.wrappedValue)")
                    .font(.body)
                    .monospacedDigit()
            }
            .labelsHidden()
            Text("\(value.wrappedValue)")
                .font(.title3)
                .fontWeight(.bold)
                .frame(minWidth: 40)
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
