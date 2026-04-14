import SwiftUI

struct ReportContentSheet: View {
    enum ContentType: String {
        case post = "Post"
        case comment = "Comment"
    }
    
    let type: ContentType
    let onSubmit: (String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedReason: String?
    @State private var details: String = ""
    
    private let reasons: [(label: String, value: String)] = [
        ("Harassment or bullying", "harassment"),
        ("Hate or abuse", "hate_speech"),
        ("Sexual content", "sexual_content"),
        ("Spam or scam", "spam"),
        ("Misinformation", "misinformation"),
        ("Other", "other")
    ]
    
    var body: some View {
        ZStack {
            EliteBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Report \(type.rawValue)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Introduction
                        Text("Why are you reporting this \(type.rawValue.lowercased())?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        
                        // Reasons List
                        VStack(spacing: 12) {
                            ForEach(reasons, id: \.value) { reason in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedReason = reason.value
                                    }
                                }) {
                                    HStack {
                                        Text(reason.label)
                                            .font(.system(size: 16, weight: selectedReason == reason.value ? .semibold : .medium))
                                            .foregroundStyle(selectedReason == reason.value ? .primary : .secondary)
                                        
                                        Spacer()
                                        
                                        if selectedReason == reason.value {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.eliteAccentPrimary)
                                                .font(.system(size: 20))
                                                .transition(.scale.combined(with: .opacity))
                                        } else {
                                            Circle()
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .frame(height: 56)
                                    .background(
                                        selectedReason == reason.value
                                            ? Color.eliteAccentPrimary.opacity(0.08)
                                            : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedReason == reason.value ? Color.eliteAccentPrimary.opacity(0.3) : Color.secondary.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extra details (optional)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            TextField("Provide context to help our moderators...", text: $details, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(16)
                                .background(
                                    colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.white.opacity(0.5)),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                
                // Submit Button
                VStack {
                    Divider()
                        .padding(.bottom, 16)
                    
                    Button(action: {
                        if let reason = selectedReason {
                            onSubmit(reason, details.isEmpty ? nil : details)
                        }
                    }) {
                        Text("Submit Report")
                    }
                    .buttonStyle(ElitePrimaryButtonStyle())
                    .disabled(selectedReason == nil)
                    .opacity(selectedReason == nil ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.white.opacity(0.95)))
            }
        }
    }
}
