import SwiftUI

struct EliteTextFieldStyle: ViewModifier {
    var isFocused: Bool = false
    var isError: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .foregroundColor(.primary)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isError ? Color.red.opacity(0.8) :
                            (isFocused ? Color.eliteAccentPrimary.opacity(0.8) : Color.secondary.opacity(0.2)),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(color: isFocused ? Color.eliteAccentPrimary.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
    }
}

extension View {
    func eliteTextFieldStyle(isFocused: Bool = false, isError: Bool = false) -> some View {
        self.modifier(EliteTextFieldStyle(isFocused: isFocused, isError: isError))
    }
}
