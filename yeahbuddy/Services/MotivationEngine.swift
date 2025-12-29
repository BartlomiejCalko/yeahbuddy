//
//  MotivationEngine.swift
//  yeahbuddy
//
//  Created by Assistant on 22/12/2025.
//

import Foundation

class MotivationEngine {
    
    static func getMotivation(repsRemaining: Int) -> String {
        switch repsRemaining {
        case 5:
            return "Five more, let's go!"
        case 3:
            return "Push it! Just 3 left."
        case 1:
            return "Last one, make it count!"
        case 0:
            return "Yeah buddy! Light weight!"
        default:
            return ""
        }
    }
}
