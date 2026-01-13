//
//  JournalSuggestionPicker.swift
//  Rewind
//
//  Created for Synthify on 11/11/25.
//

import SwiftUI
#if canImport(JournalingSuggestions)
import JournalingSuggestions
#endif

@available(iOS 17.2, *)
struct JournalSuggestionPicker: View {
    var onCompletion: (String) -> Void
    
    @State private var showMockSheet = false
    
    var body: some View {
        #if targetEnvironment(simulator)
        // MOCK IMPLEMENTATION FOR SIMULATOR: Button -> Sheet
        Button(action: {
            showMockSheet = true
        }) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill") // Standard-ish icon
                Text("Suggestions")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .sheet(isPresented: $showMockSheet) {
            NavigationStack {
                List {
                    Button("🏃 Morning Run (Mock)") {
                        onCompletion("Inspired by a morning run")
                        showMockSheet = false
                    }
                    Button("☕ Coffee at Central Perk (Mock)") {
                        onCompletion("Inspired by coffee time")
                        showMockSheet = false
                    }
                    Button("📸 Photo from yesterday (Mock)") {
                        onCompletion("Inspired by a photo memory")
                        showMockSheet = false
                    }
                }
                .navigationTitle("Simulator Mode")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showMockSheet = false }
                    }
                }
            }
        }
        #else
        // REAL DEVICE IMPLEMENTATION
        #if canImport(JournalingSuggestions)
        JournalingSuggestionsPicker {
            Text("Journaling Suggestions")
        } onCompletion: { result in
             print("Received suggestion result: \(result)")
             // In a real app, you'd process 'result'
             Task {
                 let formatter = DateFormatter()
                 formatter.dateStyle = .medium
                 let dateStr = formatter.string(from: Date())
                 onCompletion("Inspired by suggestion from \(dateStr)")
            }
        }
        #else
        VStack {
            Text("Journaling Suggestions not available in this build")
                .padding()
            Button("Simulate Selection") {
                onCompletion("Manual fallback selection")
            }
        }
        #endif
        #endif
    }
}
