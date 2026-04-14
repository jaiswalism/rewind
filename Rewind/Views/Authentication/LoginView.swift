import SwiftUI
import UIKit
import Supabase
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appleSignInManager = AppleSignInManager()
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    // Callbacks for routing
    var onLoginSuccess: ((_ onboardingCompleted: Bool) -> Void)?
    var onOAuthSuccess: ((_ onboardingCompleted: Bool) -> Void)?
    var onSignUpTapped: (() -> Void)?
    var onForgotPasswordTapped: (() -> Void)?
    
    var body: some View {
        ZStack {
            EliteBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    // Header Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                            .tracking(-0.5)
                        
                        Text("Sign in to your account.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 80)
                    .padding(.bottom, 20)
                    
                    // Input Form Card
                    VStack(spacing: 0) {
                        TextField("Email Address", text: $email, prompt: Text("Email Address").foregroundStyle(.secondary))
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
                    
                    // Forgot Password Button
                    HStack {
                        Spacer()
                        Button(action: {
                            onForgotPasswordTapped?()
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.eliteAccentPrimary)
                        }
                    }
                    
                    VStack(spacing: 24) {
                        // Login Button
                        Button(action: performLogin) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log In")
                            }
                        }
                        .buttonStyle(ElitePrimaryButtonStyle())
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        
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
                            Button(action: { performOAuthLogin(provider: .google) }) {
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
                            .disabled(authViewModel.isLoading)
                            
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
                            .disabled(authViewModel.isLoading)
                        }
                    }
                    
                    // Sign Up Link
                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            onSignUpTapped?()
                        }) {
                            Text("Sign Up")
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
            
            // Error overlay
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
    
    private func performLogin() {
        focusedField = nil
        guard !email.isEmpty, !password.isEmpty else { return }
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        Task {
            do {
                try await authViewModel.login(email: email, password: password)
                
                // If login succeeds, it does not throw.
                // We resolve the silent block by navigating independently of parsing failures.
                let isCompleted = authViewModel.currentUser?.onboardingCompleted ?? false
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                onLoginSuccess?(isCompleted)
                
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }

    private func performOAuthLogin(provider: Provider) {
        guard !authViewModel.isLoading else { return }

        focusedField = nil

        Task {
            do {
                try await authViewModel.signInWithOAuth(provider: provider)
                let isCompleted = authViewModel.currentUser?.onboardingCompleted ?? false
                if let onOAuthSuccess = onOAuthSuccess {
                    onOAuthSuccess(isCompleted)
                } else {
                    onLoginSuccess?(isCompleted)
                }
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }

    private func performNativeAppleSignIn() {
        guard !authViewModel.isLoading else { return }
        focusedField = nil
        appleSignInManager.startSignInWithAppleFlow { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resultTuple):
                    Task {
                        do {
                            try await authViewModel.signInWithAppleNative(idToken: resultTuple.idToken, nonce: resultTuple.nonce, fullName: resultTuple.fullName)
                            let isCompleted = authViewModel.currentUser?.onboardingCompleted ?? false
                            if let onOAuthSuccess = onOAuthSuccess {
                                onOAuthSuccess(isCompleted)
                            } else {
                                onLoginSuccess?(isCompleted)
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
