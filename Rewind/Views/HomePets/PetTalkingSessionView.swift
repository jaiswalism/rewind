import SwiftUI
import SceneKit

struct PetTalkingSessionView: View {
    @ObservedObject var viewModel: PetConversationSessionViewModel
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.32, green: 0.56, blue: 0.98)
    private let liveAccent = Color(red: 0.24, green: 0.74, blue: 0.56)
    private let warmAccent = Color(red: 0.95, green: 0.52, blue: 0.32)

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    modeSelector

                    if viewModel.mode == .live {
                        liveSection
                    } else {
                        typedSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear { viewModel.openSession() }
        .onDisappear { viewModel.closeSession() }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.11, blue: 0.20), Color(red: 0.14, green: 0.18, blue: 0.31)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(accent.opacity(0.22))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: -120, y: -260)
            Circle()
                .fill(liveAccent.opacity(0.20))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: 140, y: 300)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Talk to your pet")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Switch between live voice and typed chat.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("Close talk screen")
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            modeButton(title: PetConversationMode.live.title, icon: "waveform.path.ecg", isSelected: viewModel.mode == .live) {
                viewModel.selectMode(.live)
            }
            modeButton(title: PetConversationMode.type.title, icon: "text.bubble.fill", isSelected: viewModel.mode == .type) {
                viewModel.selectMode(.type)
            }
        }
        .padding(8)
        .background(.white.opacity(0.10), in: Capsule())
    }

    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? accent : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var liveSection: some View {
        VStack(spacing: 16) {
            liveAvatarCard
            liveStatusCard
        }
    }

    private var liveAvatarCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(liveAccent.opacity(0.16))
                    .frame(width: 190, height: 190)
                    .scaleEffect(1 + CGFloat(viewModel.liveAudioLevel) * 0.16)
                Circle()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .scaleEffect(1 + CGFloat(viewModel.liveAudioLevel) * 0.10)
                PetAvatarViewRepresentable(scale: 0.14, position: SCNVector3(0, -2.0, 0))
                    .frame(width: 220, height: 220)
                    .scaleEffect(1 + CGFloat(viewModel.liveAudioLevel) * 0.05)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Button {
                viewModel.toggleLiveSession()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: liveButtonIcon)
                        .font(.system(size: 16, weight: .bold))
                    Text(viewModel.liveActionTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(liveButtonColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLiveButtonDisabled)
        }
        .padding(18)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var liveStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live status")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.0)

            Text(viewModel.liveStatusText.isEmpty ? "Say something to your pet." : viewModel.liveStatusText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.liveReplyText.isEmpty {
                Text(viewModel.liveReplyText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var typedSection: some View {
        VStack(spacing: 16) {
            typedMessageList
            typedComposer
        }
    }

    private var typedMessageList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chat")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.0)

            if viewModel.typedMessages.isEmpty {
                Text("Your typed messages will appear here.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.typedMessages) { message in
                        MessageBubble(message: message)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var typedComposer: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type a message...", text: $viewModel.typedMessage)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .submitLabel(.send)
                .onSubmit { viewModel.submitTypedMessage() }

            Button {
                viewModel.submitTypedMessage()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.typedStateIsSending ? "arrow.up.circle.fill" : "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(viewModel.typedStateIsSending ? "Sending..." : "Send")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.canSendTypedMessage ? warmAccent : Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSendTypedMessage)

            Text(viewModel.typedStatusText.isEmpty ? " " : viewModel.typedStatusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var liveButtonIcon: String {
        switch viewModel.liveState {
        case .listening, .responding: return "stop.fill"
        case .connecting: return "hourglass"
        case .error: return "arrow.clockwise"
        default: return "mic.fill"
        }
    }

    private var liveButtonColor: Color {
        switch viewModel.liveState {
        case .listening, .responding: return Color(red: 0.88, green: 0.28, blue: 0.28)
        case .connecting: return Color(red: 0.46, green: 0.46, blue: 0.96)
        case .error: return Color(red: 0.86, green: 0.42, blue: 0.24)
        default: return liveAccent
        }
    }

    private var isLiveButtonDisabled: Bool {
        if case .connecting = viewModel.liveState {
            return true
        }
        return false
    }
}

private struct MessageBubble: View {
    let message: PetConversationMessage

    var body: some View {
        HStack {
            if message.role == .pet { bubble; Spacer(minLength: 24) } else { Spacer(minLength: 24); bubble }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(message.role == .pet ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(messageBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: 260, alignment: message.role == .pet ? .leading : .trailing)
    }

    private var messageBackground: Color {
        switch message.role {
        case .pet:
            return Color.white.opacity(0.12)
        case .user:
            return Color(red: 0.95, green: 0.81, blue: 0.50)
        }
    }
}

private extension PetConversationSessionViewModel {
    var typedStateIsSending: Bool {
        if case .sending = typedState { return true }
        return false
    }
}
