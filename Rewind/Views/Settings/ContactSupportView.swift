import SwiftUI
import Supabase
import Auth

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var userViewModel = UserViewModel.shared
    
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var contactEmail: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var errorMessage: String?
    
    @State private var needsContactEmail: Bool = true
    
    var body: some View {
        ZStack {
            EliteBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contact Support")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("We're here to help you.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary, .ultraThinMaterial)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Action: Direct Email
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Action")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                                .tracking(1.0)
                            
                            Button(action: openMailApp) {
                                HStack {
                                    Image(systemName: "envelope.badge.fill")
                                        .font(.system(size: 18))
                                    Text("Send Email Directly")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .opacity(0.5)
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 60)
                                .background(Color.eliteAccentPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.eliteAccentPrimary.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundStyle(colorScheme == .dark ? Color.eliteAccentSecondary : Color.eliteAccentPrimary)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        // Structured Form
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Send a Message")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                                .tracking(1.0)
                            
                            // Contact Email Field (Conditional)
                            if needsContactEmail {
                                fieldSection(title: "Contact Email", subtitle: "Where should we reply?") {
                                    TextField("your@email.com", text: $contactEmail)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                            }
                            
                            fieldSection(title: "Subject") {
                                TextField("What's this regarding?", text: $subject)
                            }
                            
                            fieldSection(title: "Message") {
                                TextField("Describe your issue or feedback...", text: $message, axis: .vertical)
                                    .lineLimit(5...10)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                
                // Submit Button
                VStack(spacing: 12) {
                    Divider()
                        .padding(.bottom, 8)
                    
                    Button(action: submitForm) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit Support Request")
                        }
                    }
                    .buttonStyle(ElitePrimaryButtonStyle())
                    .disabled(isSubmitting || !isFormValid)
                    .opacity(!isFormValid ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    
                    Text("A copy of this request will be sent to your email.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
                .background(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.white.opacity(0.95)))
            }
        }
        .onAppear(perform: checkUserSession)
        .task {
            // Also run as a task for better async timing
            checkUserSession()
        }
        .onChange(of: userViewModel.user) { _, newUser in
            let current = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if current.isEmpty, let email = newUser?.email, !email.isEmpty {
                contactEmail = email
            }
        }
        .onChange(of: userViewModel.identities) { _, _ in
            checkUserSession()
        }
        .alert("Support", isPresented: $showSuccessBanner) {
            Button("OK") { dismiss() }
        } message: {
            Text("Thanks! Your message has been received. We'll get back to you soon.")
        }
        .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var isFormValid: Bool {
        if needsContactEmail && contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        return !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @ViewBuilder
    private func fieldSection<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                if let subtitle = subtitle {
                    Text("• \(subtitle)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            content()
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
    }
    
    private func checkUserSession() {
        let currentEmail = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check VM immediately
        if currentEmail.isEmpty, let email = userViewModel.user?.email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.contactEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 2. Check Identities for visibility logic
        let identities = userViewModel.identities
        if !identities.isEmpty {
            let hasEmailProvider = identities.contains(where: { $0.provider == "email" })
            self.needsContactEmail = !hasEmailProvider
        }
        
        // 3. Robust session fetch for fallback
        Task {
            let supabase = SupabaseConfig.shared.client
            guard let session = try? await supabase.auth.session else { return }
            
            let idents = session.user.identities ?? []
            let hasEmail = idents.contains(where: { $0.provider == "email" })
            
            await MainActor.run {
                self.needsContactEmail = !hasEmail
                
                // If still empty after VM check, try every possible email source
                let nowEmail = self.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                if nowEmail.isEmpty {
                    if let email = session.user.email, !email.isEmpty {
                        self.contactEmail = email
                    } else if let metaValue = session.user.userMetadata["email"] {
                        let metaEmail = String(describing: metaValue).replacingOccurrences(of: "\"", with: "")
                        if !metaEmail.isEmpty && metaEmail != "null" {
                            self.contactEmail = metaEmail
                        }
                    }
                }
            }
        }
    }
    
    private func openMailApp() {
        let mailto = "mailto:rewind@shyamjaiswal.in?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: mailto), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func submitForm() {
        isSubmitting = true
        
        Task {
            do {
                let supabase = SupabaseConfig.shared.client
                let session = try await supabase.auth.session
                
                // Explicitly notify the developer through our Edge function.
                // We'll reuse the same pattern as report-notification but with a support flag or similar logic.
                // For now, we'll try to use a "support" endpoint if it existed, 
                // but since I'm implementing based on plan, I'll stick to a mock success or actual fetch if I generalize.
                
                var request = URLRequest(url: SupabaseSecrets.supabaseURL.appendingPathComponent("functions/v1/report-notification"))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(SupabaseSecrets.supabaseKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                
                let payload: [String: Any] = [
                    "type": "Support Ticket",
                    "subject": subject,
                    "message": message,
                    "contact_email": contactEmail,
                    "user_id": session.user.id.uuidString,
                    "reporter_id": session.user.id.uuidString, // reuse same field for the notification logic
                    "reason": "Support: \(subject)",
                    "details": message + "\n\nContact: \(contactEmail)"
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    await MainActor.run {
                        isSubmitting = false
                        showSuccessBanner = true
                    }
                } else {
                    throw NSError(domain: "Support", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to send request. Please try direct email."])
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
