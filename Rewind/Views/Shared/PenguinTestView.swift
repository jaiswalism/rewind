import SwiftUI

struct PenguinTestView: View {
    @State private var mood: Int = 70
    @State private var energy: Int = 60
    
    var body: some View {
        VStack(spacing: 30) {
            PenguinView(
                mood: mood,
                energy: energy,
                behaviorPolicy: .silentCompanion
            )
            .frame(width: 300, height: 300)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.2),
                        Color.blue.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Mood: \(mood)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Slider(value: Binding(
                        get: { Double(mood) },
                        set: { mood = Int($0) }
                    ), in: 0...100)
                    .tint(.purple)
                }
                
                VStack(spacing: 8) {
                    Text("Energy: \(energy)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Slider(value: Binding(
                        get: { Double(energy) },
                        set: { energy = Int($0) }
                    ), in: 0...100)
                    .tint(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    PenguinTestView()
}
