import SwiftUI
import Supabase

// MARK: - Settings View

struct SettingsView: View {

    // MARK: - Dependencies / Callbacks
    var onBack: () -> Void = {}
    var onPersonalInfoTapped: () -> Void = {}
    var onLogOut: () -> Void = {}

    // MARK: - State
    @StateObject private var userViewModel = UserViewModel.shared
    @StateObject private var journalViewModel = JournalViewModel()

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            EliteBackgroundView()

            VStack(spacing: 0) {
                navBar
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .zIndex(10)

                ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.top, 24)

                    statsStrip
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    sectionHeader("General Settings")
                        .padding(.top, 36)
                        .padding(.horizontal, 24)

                    settingsCard {
                        settingsRow(icon: "person.fill", title: "Personal Information", action: onPersonalInfoTapped)
                        Divider().padding(.leading, 70)
                        settingsRow(icon: "square.and.arrow.up", title: "Invite Friends", action: {})
                        Divider().padding(.leading, 70)
                        settingsRow(icon: "message.fill", title: "Submit Feedback", action: {})
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                    sectionHeader("Account")
                        .padding(.top, 36)
                        .padding(.horizontal, 24)

                    settingsCard {
                        logOutRow()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 60)
                }
            }
        }
        }
        .ignoresSafeArea(.all, edges: .top)
        .task {
            await userViewModel.fetchProfile()
            await journalViewModel.fetchJournals(refresh: true)
        }
    }

    // MARK: - Navigation Bar

    private var navBar: some View {
        HStack {
            Button(action: onBack) {
                Group {
                    if #available(iOS 26, *) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                    }
                }
                .overlay(Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .offset(x: -22)
            
            Spacer()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(Color.eliteAccentPrimary.opacity(0.35), lineWidth: 3)
                    .frame(width: 132, height: 132)

                if let urlString = userViewModel.user?.profileImageUrl,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.eliteAccentPrimary.opacity(0.15))
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.eliteAccentPrimary.opacity(0.15))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.eliteAccentPrimary.opacity(0.15))
                                .frame(width: 120, height: 120)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.eliteAccentPrimary.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                        )
                }
            }

            // Name
            Text(userViewModel.user?.name ?? " ")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)

            // Email
            if let email = userViewModel.user?.email, !email.isEmpty {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Location
            if let location = userViewModel.user?.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.eliteAccentPrimary)
                    Text(location)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell(value: "\(journalViewModel.pagination?.total ?? journalViewModel.journals.count)", label: "Journals")
            Divider()
                .frame(width: 1, height: 36)
                .overlay(Color.secondary.opacity(0.25))
            statCell(value: "\(userViewModel.user?.totalPosts ?? 0)", label: "Posts")
            Divider()
                .frame(width: 1, height: 36)
                .overlay(Color.secondary.opacity(0.25))
            statCell(value: "\(userViewModel.user?.pawsBalance ?? 0)", label: "Paws")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon pill
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.eliteAccentPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.eliteAccentPrimary)
                    )

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    private func logOutRow() -> some View {
        Button(action: performLogOut) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.red)
                    )

                Text("Log Out")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.red)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    // MARK: - Log Out Logic

    private func performLogOut() {
        Task {
            try? await SupabaseConfig.shared.client.auth.signOut()
            await MainActor.run { onLogOut() }
        }
    }
}

// MARK: - Button Style

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.primary.opacity(0.06)
                    : Color.clear
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
