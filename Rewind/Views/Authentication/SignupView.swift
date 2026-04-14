import SwiftUI
import Supabase
import AuthenticationServices

struct SignupView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appleSignInManager = AppleSignInManager()
    
    @State private var name = ""
    @State private var emailPhone = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isEULAAgreed = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    // Callbacks for routing
    var onSignUpSuccess: (() -> Void)?
    var onOAuthSuccess: ((_ onboardingCompleted: Bool) -> Void)?
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
                        
                        // EULA Agreement
                        Toggle(isOn: $isEULAAgreed) {
                            Text("I agree to the [Terms of Service](https://rewind.shyamjaiswal.in/terms) & [Privacy Policy](https://rewind.shyamjaiswal.in/privacy). Rewind maintains zero tolerance for objectionable content; violations lead to immediate account removal.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color.eliteAccentPrimary))
                        .padding(.horizontal, 4)
                        
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
                        .disabled(authViewModel.isLoading || name.isEmpty || emailPhone.isEmpty || password.isEmpty || !isEULAAgreed)
                        .opacity(name.isEmpty || emailPhone.isEmpty || password.isEmpty || !isEULAAgreed ? 0.6 : 1.0)
                        
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
                            Button(action: { performOAuthSignIn(provider: .google) }) {
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
                            .disabled(authViewModel.isLoading || !isEULAAgreed)
                            .opacity(!isEULAAgreed ? 0.6 : 1.0)
                            
                            Button(action: { performNativeAppleSignIn() }) {
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
                            .disabled(authViewModel.isLoading || !isEULAAgreed)
                            .opacity(!isEULAAgreed ? 0.6 : 1.0)
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

    private func performOAuthSignIn(provider: Provider) {
        guard !authViewModel.isLoading, isEULAAgreed else { return }

        focusedField = nil

        Task {
            do {
                try await authViewModel.signInWithOAuth(provider: provider)
                let isCompleted = authViewModel.currentUser?.onboardingCompleted ?? false
                if let onOAuthSuccess = onOAuthSuccess {
                    onOAuthSuccess(isCompleted)
                } else {
                    onSignUpSuccess?()
                }
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }

    private func performNativeAppleSignIn() {
        guard !authViewModel.isLoading, isEULAAgreed else { return }
        focusedField = nil
        appleSignInManager.startSignInWithAppleFlow { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resultTuple):
                    Task {
                        do {
                            // Store name for the onboarding submit — Apple only sends it once
                            OnboardingDataManager.shared.displayName = resultTuple.fullName
                            try await authViewModel.signInWithAppleNative(idToken: resultTuple.idToken, nonce: resultTuple.nonce, fullName: resultTuple.fullName)
                            let isCompleted = authViewModel.currentUser?.onboardingCompleted ?? false
                            if let onOAuthSuccess = onOAuthSuccess {
                                onOAuthSuccess(isCompleted)
                            } else {
                                onSignUpSuccess?()
                            }
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        }
                    }
                case .failure(let error):
                    guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
                    authViewModel.error = error.localizedDescription
                }
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
