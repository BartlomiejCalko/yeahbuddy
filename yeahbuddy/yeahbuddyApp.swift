//
//  yeahbuddyApp.swift
//  yeahbuddy
//
//  Created by Bartlomiej Calko on 22/12/2025.
//

import SwiftUI

@main
struct yeahbuddyApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                SetupView()
            } else {
                OnboardingView()
            }
        }
    }
}
