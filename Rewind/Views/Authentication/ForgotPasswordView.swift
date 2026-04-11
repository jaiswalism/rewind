import SwiftUI
import UIKit

struct ForgotPasswordView: View {
    @StateObject private var authViewModel = AuthViewModel()

    @State private var email = ""
    @State private var didSendCode = false
    @State private var toastMessage: String?
    @State private var isToastError = false
    @FocusState private var isEmailFocused: Bool

    var onBackTapped: (() -> Void)?
    var onCodeSent: ((String) -> Void)?
    var prefilledEmail: String?

    init(prefilledEmail: String? = nil) {
        self.prefilledEmail = prefilledEmail
    }

    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    requestCard
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.top, 34)
                .padding(.bottom, 24)
            }
            .onTapGesture { isEmailFocused = false }

            if let toastMessage {
                toastView(message: toastMessage, isError: isToastError)
            }
        }
        .onAppear {
            if let prefilledEmail, email.isEmpty {
                email = prefilledEmail
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { onBackTapped?() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)

            Text("Reset Password")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text("Enter your account email and we will send a one-time code.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var requestCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                TextField("Email Address", text: $email, prompt: Text("Email Address").foregroundStyle(.secondary))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isEmailFocused)
                    .padding()
                    .frame(height: 56)

                Divider().padding(.leading, 16)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.rotation")
                        .foregroundStyle(Color.eliteAccentPrimary)
                    Text("Check your inbox for the verification code and enter it in the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(UIColor.separator).opacity(0.45), lineWidth: 0.5)
            )

            Button(action: sendResetLink) {
                if authViewModel.isLoading {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Text(didSendCode ? "Code Sent" : "Send Code")
                }
            }
            .buttonStyle(ElitePrimaryButtonStyle())
            .disabled(authViewModel.isLoading || !isValidEmail(email) || didSendCode)
            .opacity((isValidEmail(email) && !didSendCode) ? 1 : 0.6)

            Button(action: {
                onCodeSent?(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            }) {
                Text("Continue To Enter Code")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(didSendCode ? Color.eliteAccentPrimary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .disabled(!didSendCode)
            .opacity(didSendCode ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private func toastView(message: String, isError: Bool) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding()
            .background((isError ? Color.red : Color.green).opacity(0.9))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer(minLength: 0)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func showToast(_ message: String, isError: Bool) {
        isToastError = isError
        withAnimation {
            toastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                toastMessage = nil
            }
        }
    }

    private func sendResetLink() {
        guard isValidEmail(email) else { return }
        isEmailFocused = false

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                try await authViewModel.forgotPassword(email: email)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                didSendCode = true
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.UserDefaults.passwordResetCodeSentAt)
                showToast("If the account exists, a code has been sent.", isError: false)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showToast(authViewModel.error ?? "Unable to send code.", isError: true)
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }
}

#Preview {
    ForgotPasswordView()
}
