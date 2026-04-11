import SwiftUI
import UIKit

struct ResetPasswordView: View {
    @StateObject private var authViewModel = AuthViewModel()

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false
    @State private var didUpdatePassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case password
        case confirmPassword
    }

    var onDoneTapped: (() -> Void)?

    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    formCard
                    actionButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.top, 70)
                .padding(.bottom, 24)
            }
            .onTapGesture { focusedField = nil }

            if let errorMessage = authViewModel.error {
                errorBanner(message: errorMessage)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create New Password")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text(didUpdatePassword
                 ? "Password updated. You can continue to your account."
                 : "Choose a strong password you have not used before.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            passwordField(
                title: "New Password",
                text: $password,
                isVisible: $isPasswordVisible,
                field: .password
            )

            Divider().padding(.leading, 16)

            passwordField(
                title: "Confirm Password",
                text: $confirmPassword,
                isVisible: $isConfirmVisible,
                field: .confirmPassword
            )
        }
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.separator).opacity(0.45), lineWidth: 0.5)
        )
    }

    private var actionButton: some View {
        Button(action: updatePassword) {
            if authViewModel.isLoading {
                ProgressView().progressViewStyle(.circular)
            } else {
                Text(didUpdatePassword ? "Continue to Login" : "Update Password")
            }
        }
        .buttonStyle(ElitePrimaryButtonStyle())
        .disabled(authViewModel.isLoading || (!didUpdatePassword && !isValidForm))
        .opacity((didUpdatePassword || isValidForm) ? 1 : 0.6)
    }

    private func passwordField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        field: Field
    ) -> some View {
        HStack {
            if isVisible.wrappedValue {
                TextField(title, text: text, prompt: Text(title).foregroundStyle(.secondary))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: field)
            } else {
                SecureField(title, text: text, prompt: Text(title).foregroundStyle(.secondary))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: field)
            }

            Button(action: { withAnimation { isVisible.wrappedValue.toggle() } }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(height: 56)
    }

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding()
            .background(Color.red.opacity(0.85))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer(minLength: 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    authViewModel.error = nil
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: authViewModel.error)
    }

    private var isValidForm: Bool {
        password.count >= 8 && password == confirmPassword
    }

    private func updatePassword() {
        if didUpdatePassword {
            onDoneTapped?()
            return
        }

        guard isValidForm else { return }
        focusedField = nil

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                try await authViewModel.updatePassword(newPassword: password)
                didUpdatePassword = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    ResetPasswordView()
}
