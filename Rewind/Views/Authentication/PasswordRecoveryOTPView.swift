import SwiftUI
import UIKit
import Combine

struct PasswordRecoveryOTPView: View {
    @StateObject private var authViewModel = AuthViewModel()

    @State private var code = ""
    @State private var resendCooldown = 0
    @State private var hasVerifiedCode = false
    @State private var toastMessage: String?
    @State private var isToastError = false
    @FocusState private var isCodeFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    let email: String
    var onBackTapped: (() -> Void)?
    var onVerified: (() -> Void)?

    private let cooldownSeconds = 30
    private let requiredCodeLength = 8
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    codeCard
                    actionButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.top, 34)
                .padding(.bottom, 24)
            }
            .onTapGesture { isCodeFocused = false }
            .onChange(of: code) { _, newValue in
                let digitsOnly = newValue.filter(\.isNumber)
                if digitsOnly != newValue {
                    code = String(digitsOnly.prefix(8))
                } else if digitsOnly.count > 8 {
                    code = String(digitsOnly.prefix(8))
                }
            }
            .onReceive(ticker) { _ in
                refreshResendCooldown()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshResendCooldown()
                }
            }

            if let toastMessage {
                toastView(message: toastMessage, isError: isToastError)
            }
        }
        .onAppear {
            ensureCodeSentTimestampExists()
            refreshResendCooldown()
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
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)

            Text("Enter Verification Code")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text("We sent a one-time code to \(email).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var codeCard: some View {
        VStack(spacing: 16) {
            TextField("12345678", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .padding()
                .frame(height: 64)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.separator).opacity(0.45), lineWidth: 0.5)
                )
                .focused($isCodeFocused)

            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Color.eliteAccentPrimary)
                Text("Use the latest code only. It expires quickly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            Button(action: resendCode) {
                if authViewModel.isLoading {
                    ProgressView().progressViewStyle(.circular)
                } else if resendCooldown > 0 {
                    Text("Resend in \(resendCooldown)s")
                } else {
                    Text("Resend Code")
                }
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(resendCooldown > 0 ? .secondary : Color.eliteAccentPrimary)
            .disabled(authViewModel.isLoading || resendCooldown > 0)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Not receiving a code? You probably do not have an account yet. Please sign up first.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(UIColor.separator).opacity(0.45), lineWidth: 0.5)
        )
    }

    private var actionButton: some View {
        Button(action: verifyCode) {
            if authViewModel.isLoading {
                ProgressView().progressViewStyle(.circular)
            } else {
                Text(hasVerifiedCode ? "Continue" : "Verify Code")
            }
        }
        .buttonStyle(ElitePrimaryButtonStyle())
        .disabled(authViewModel.isLoading || normalizedCode.count != requiredCodeLength)
        .opacity(normalizedCode.count == requiredCodeLength ? 1 : 0.6)
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

    private var normalizedCode: String {
        code.filter(\.isNumber)
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

    private func resendCode() {
        guard resendCooldown == 0 else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            do {
                try await authViewModel.resendPasswordReset(email: email)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.UserDefaults.passwordResetCodeSentAt)
                refreshResendCooldown()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showToast("A new code has been sent.", isError: false)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showToast(authViewModel.error ?? "Unable to resend code right now.", isError: true)
            }
        }
    }

    private func ensureCodeSentTimestampExists() {
        let key = Constants.UserDefaults.passwordResetCodeSentAt
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
        }
    }

    private func refreshResendCooldown() {
        let key = Constants.UserDefaults.passwordResetCodeSentAt
        let sentAtTimestamp = UserDefaults.standard.double(forKey: key)
        guard sentAtTimestamp > 0 else {
            resendCooldown = cooldownSeconds
            return
        }

        let sentAt = Date(timeIntervalSince1970: sentAtTimestamp)
        let availableAt = sentAt.addingTimeInterval(TimeInterval(cooldownSeconds))
        let remaining = Int(ceil(availableAt.timeIntervalSinceNow))
        resendCooldown = max(0, remaining)
    }

    private func verifyCode() {
        guard normalizedCode.count == requiredCodeLength else {
            showToast("Enter the full \(requiredCodeLength)-digit verification code.", isError: true)
            return
        }
        isCodeFocused = false

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                try await authViewModel.verifyPasswordResetOTP(email: email, code: normalizedCode)
                hasVerifiedCode = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showToast("Code verified.", isError: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onVerified?()
                }
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showToast(authViewModel.error ?? "Invalid code. Try again.", isError: true)
            }
        }
    }
}

#Preview {
    PasswordRecoveryOTPView(email: "user@example.com")
}
