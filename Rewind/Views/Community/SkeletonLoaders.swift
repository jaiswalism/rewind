import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: shimmerColor.opacity(0.4), location: 0.3),
                            .init(color: shimmerColor.opacity(0.8), location: 0.5),
                            .init(color: shimmerColor.opacity(0.4), location: 0.7),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
    
    private var shimmerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.05)
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct CommunityPostSkeleton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 24, height: 24)
            }
            
            // Content Line 1
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(maxWidth: .infinity)
                .frame(height: 14)
            
            // Content Line 2
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 14)
            
            // Media Placeholder (simulating a potential image/box)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            
            // Footer (Actions)
            HStack(spacing: 24) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 20, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 30, height: 12)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shimmering()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            CommunityPostSkeleton()
            CommunityPostSkeleton()
        }
        .padding()
    }
}
