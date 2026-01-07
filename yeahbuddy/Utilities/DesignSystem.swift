
import SwiftUI

// MARK: - Colors
struct YBColors {
    static let backgroundStart = Color(hex: "4c1d95") // Deep Violet
    static let backgroundEnd = Color(hex: "2563eb")   // Royal Blue
    
    static let neonGreen = Color(hex: "4ade80")
    static let neonPink = Color(hex: "f472b6")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - Gradients
struct YBGradients {
    static let mainBackground = LinearGradient(
        gradient: Gradient(colors: [YBColors.backgroundStart, YBColors.backgroundEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassBorder = LinearGradient(
        gradient: Gradient(colors: [.white.opacity(0.5), .white.opacity(0.1)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Modifiers
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .environment(\.colorScheme, .dark)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(YBGradients.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}

// MARK: - Helper Text Extensions
extension Text {
    func ybTitle() -> some View {
        self.font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundColor(YBColors.textPrimary)
    }
    
    func ybSubtitle() -> some View {
        self.font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundColor(YBColors.textSecondary)
    }
    
    func ybValue() -> some View {
        self.font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundColor(YBColors.textPrimary)
    }
}

// MARK: - Hex Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
