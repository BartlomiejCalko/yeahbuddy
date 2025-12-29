//
//  ContentView.swift
//  yeahbuddy
//
//  Created by Bartlomiej Calko on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab(Constants.homeString, systemImage: "house") {
                Text(Constants.homeString)
            }
            
        }
    }
}

#Preview {
    ContentView()
}
