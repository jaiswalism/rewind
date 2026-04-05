import SwiftUI

// MARK: - Button Style Extensions

extension Button {
    func primaryStyle() -> some View {
        buttonStyle(ElitePrimaryButtonStyle())
    }
    
    func socialStyle() -> some View {
        buttonStyle(EliteSocialButtonStyle())
    }
}

// MARK: - View Modifiers

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(ElitePrimaryButtonStyle())
    }
}

struct SocialButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(EliteSocialButtonStyle())
    }
}

extension View {
    func primaryButton() -> some View {
        modifier(PrimaryButtonModifier())
    }
    
    func socialButton() -> some View {
        modifier(SocialButtonModifier())
    }
}
