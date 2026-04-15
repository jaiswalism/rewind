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
        let r: UInt64
        let g: UInt64
        let b: UInt64
        let resolvedOpacity: Double
        switch hex.count {
        case 3:
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17
            resolvedOpacity = opacity
        case 6:
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
            resolvedOpacity = opacity
        case 8:
            let a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
            resolvedOpacity = Double(a) / 255 * opacity
        default:
            r = 1
            g = 1
            b = 0
            resolvedOpacity = opacity
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: resolvedOpacity
        )
    }
}

// MARK: - Sophisticated Mesh Background
struct EliteBackgroundView: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var orbOpacity: Double { colorScheme == .dark ? 0.08 : 0.12 }
    
    var body: some View {
        ZStack {
            // Adaptive base — Soft matte tint in light mode, system background in dark
            (colorScheme == .dark ? Color(UIColor.systemBackground) : Color(red: 0.96, green: 0.97, blue: 0.98))
                .ignoresSafeArea()
            
            // Smoothly floating and blending ambient orbs
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.eliteAccentPrimary.opacity(orbOpacity))
                        .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                        .blur(radius: 70)
                        .offset(x: animate ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animate ? -geometry.size.height * 0.1 : geometry.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.eliteAccentSecondary.opacity(orbOpacity))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .blur(radius: 70)
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
