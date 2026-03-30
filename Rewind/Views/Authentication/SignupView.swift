import SwiftUI

struct SignupView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    @State private var name = ""
    @State private var emailPhone = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    // Callbacks for routing
    var onSignUpSuccess: (() -> Void)?
    var onSignInTapped: (() -> Void)?
    
    var body: some View {
        ZStack {
            EliteBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Header Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                            .tracking(-0.5)
                        
                        Text("Join us to unlock full features.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 60)
                    .padding(.bottom, 10)
                    
                    // Input Form Card
                    VStack(spacing: 0) {
                        TextField("Full Name", text: $name, prompt: Text("Full Name").foregroundStyle(.secondary))
                            .autocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .padding()
                            .frame(height: 56)
                            .accessibilityLabel("Full Name")
                            
                        Divider().padding(.leading, 16)
                        
                        TextField("Email Address", text: $emailPhone, prompt: Text("Email Address").foregroundStyle(.secondary))
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .frame(height: 56)
                            .accessibilityLabel("Email Address")
                            
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $password, prompt: Text("Password").foregroundStyle(.secondary))
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Password", text: $password, prompt: Text("Password").foregroundStyle(.secondary))
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            Button(action: {
                                withAnimation { isPasswordVisible.toggle() }
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel(isPasswordVisible ? "Hide Password" : "Show Password")
                        }
                        .padding()
                        .frame(height: 56)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                    )
                    
                    VStack(spacing: 24) {
                        // Sign Up Button
                        Button(action: performSignUp) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                            }
                        }
                        .buttonStyle(ElitePrimaryButtonStyle())
                        .disabled(authViewModel.isLoading || name.isEmpty || emailPhone.isEmpty || password.isEmpty)
                        .opacity(name.isEmpty || emailPhone.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        
                        // Or Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 1)
                            Text("or continue with")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 1)
                        }
                        
                        // Social Login Buttons
                        VStack(spacing: 16) {
                            Button(action: { /* Google Auth */ }) {
                                HStack(spacing: 12) {
                                    Image("illustrations/auth/googleLogo")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                    Text("Google")
                                }
                            }
                            .buttonStyle(EliteSocialButtonStyle())
                            
                            Button(action: { /* Apple Auth */ }) {
                                HStack(spacing: 12) {
                                    Image("illustrations/auth/appleLogo")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 22)
                                        .foregroundStyle(.primary)
                                    Text("Apple")
                                }
                            }
                            .buttonStyle(EliteSocialButtonStyle())
                        }
                    }
                    
                    // Sign In Link
                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            onSignInTapped?()
                        }) {
                            Text("Sign In")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.eliteAccentPrimary)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
            }
            .zIndex(1)
            .onTapGesture {
                focusedField = nil
            }
            
            // Error Overlay
            if let errorMessage = authViewModel.error {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: authViewModel.error)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            authViewModel.error = nil
                        }
                    }
                }
                .zIndex(2)
            }
        }
    }
    
    private func performSignUp() {
        focusedField = nil
        guard !name.isEmpty, !emailPhone.isEmpty, !password.isEmpty else { return }
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        Task {
            do {
                try await authViewModel.register(name: name, email: emailPhone, password: password)
                
                // If register doesn't throw, we successfully signed up contextually.
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                onSignUpSuccess?()
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .preferredColorScheme(.dark)
    }
}
