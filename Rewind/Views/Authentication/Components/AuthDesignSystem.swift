import SwiftUI

extension Color {
    // Native Apple Theme Palette
    static let eliteBackground = Color(UIColor.systemBackground)
    static let eliteSurface = Color(UIColor.secondarySystemBackground)
    static let eliteBorder = Color(UIColor.separator)
    
    // Vibrant Acents
    static let eliteAccentPrimary = Color("colors/Blue&Shades/blue-500")
    static let eliteAccentSecondary = Color("colors/Blue&Shades/blue-400")
    
    static let eliteTextPrimary = Color.primary
    static let eliteTextSecondary = Color.secondary
}

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Sophisticated Mesh Background
struct EliteBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.eliteBackground.ignoresSafeArea()
            
            // Smoothly floating and blending ambient orbs (non-snapping mesh gradient alternative)
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.eliteAccentPrimary.opacity(0.12))
                        .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                        .blur(radius: 80)
                        .offset(x: animate ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animate ? -geometry.size.height * 0.1 : geometry.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.eliteAccentSecondary.opacity(0.12))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .blur(radius: 80)
                        .offset(x: animate ? geometry.size.width * 0.3 : -geometry.size.width * 0.1,
                                y: animate ? geometry.size.height * 0.2 : -geometry.size.height * 0.1)
                }
            }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

// MARK: - Premium Button Styles
struct ElitePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .default))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.eliteAccentPrimary) // Clean, native solid color instead of AI-looking gradient
            .cornerRadius(12)
            .shadow(color: Color.eliteAccentPrimary.opacity(configuration.isPressed ? 0.2 : 0.4), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct EliteSocialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
