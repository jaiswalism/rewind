import UIKit
import SwiftUI

final class PetMartViewController: UIHostingController<PetMartView> {
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(rootView: PetMartView())
        title = "Pet Mart"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

struct PetMartView: View {
    @StateObject private var userViewModel = UserViewModel.shared
    @AppStorage(Constants.UserDefaults.selectedPetMartStyle) private var selectedStyleFileName = "basicPanda"
    @AppStorage(Constants.UserDefaults.ownedPetMartStyles) private var ownedStylesCSV = "basicPanda"
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var pendingStyleFileName: String?

    private let pandaStyles: [PandaStyle] = [
        PandaStyle(name: "Basic Panda", fileName: "basicPanda", price: 500, accent: Color(red: 0.24, green: 0.56, blue: 0.95)),
        PandaStyle(name: "Waving Panda", fileName: "wavingPanda", price: 650, accent: Color(red: 0.96, green: 0.62, blue: 0.30)),
        PandaStyle(name: "Sleepy Panda", fileName: "sleepyPanda", price: 800, accent: Color(red: 0.49, green: 0.57, blue: 0.94)),
        PandaStyle(name: "Sad Panda", fileName: "sadPanda", price: 900, accent: Color(red: 0.43, green: 0.72, blue: 0.67)),
        PandaStyle(name: "Fighting Panda", fileName: "fightingPanda", price: 1000, accent: Color(red: 0.92, green: 0.34, blue: 0.29))
    ]

    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    titleSection
                    stylesGrid
                    infoCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .task {
            if userViewModel.user == nil {
                await userViewModel.fetchProfile()
            }
        }
        .alert("Pet Mart", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pet Mart")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            Text("Buy a panda style and equip it on Home.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                Text("Paws balance: \(userViewModel.user?.pawsBalance ?? 0)")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.eliteAccentPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.eliteAccentPrimary.opacity(0.12), in: Capsule())
        }
    }

    private var stylesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(pandaStyles) { style in
                styleCard(for: style)
            }
        }
    }

    private func styleCard(for style: PandaStyle) -> some View {
        let isOwned = ownedStyleSet.contains(style.fileName)
        let isSelected = selectedStyleFileName == style.fileName
        let isPending = pendingStyleFileName == style.fileName
        let balance = userViewModel.user?.pawsBalance ?? 0
        let canBuy = balance >= style.price

        return VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.accent.opacity(0.18))
                .frame(height: 92)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.seal.fill" : "tshirt.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(style.fileName)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(style.accent)
                }

            Text(style.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            Text("\(style.price) paws")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            if isSelected {
                labelChip(text: "Equipped", tint: style.accent)
            } else if isOwned {
                labelChip(text: "Owned", tint: style.accent)
            } else if canBuy {
                labelChip(text: "Available", tint: style.accent)
            } else {
                labelChip(text: "Need \(style.price - balance) more paws", tint: style.accent)
            }

            Button {
                Task { @MainActor in
                    await handleStyleTap(style)
                }
            } label: {
                HStack(spacing: 8) {
                    if isPending {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(style.accent)
                        Text("Working...")
                    } else if isSelected {
                        Image(systemName: "checkmark")
                        Text("Equipped")
                    } else if isOwned {
                        Image(systemName: "paintbrush.fill")
                        Text("Equip")
                    } else {
                        Image(systemName: "cart.fill")
                        Text("Buy & Equip")
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .foregroundStyle(isSelected ? .secondary : style.accent)
            }
            .buttonStyle(.plain)
            .disabled(isPending || isSelected || (!isOwned && !canBuy))
            .frame(height: 44)
            .background(isSelected ? style.accent.opacity(0.12) : Color.eliteSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style.accent.opacity(isSelected ? 0.45 : 0.18), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.eliteSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.eliteBorder.opacity(0.45), lineWidth: 1)
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How it works")
                .font(.system(size: 15, weight: .bold))
            Text("Buying a style deducts paws, marks it as owned, and equips it on Home right away.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.eliteSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var ownedStyleSet: Set<String> {
        Set(ownedStylesCSV.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func labelChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private func handleStyleTap(_ style: PandaStyle) async {
        let isOwned = ownedStyleSet.contains(style.fileName)

        if isOwned {
            selectedStyleFileName = style.fileName
            alertMessage = "\(style.name) is now equipped on Home."
            showingAlert = true
            return
        }

        guard (userViewModel.user?.pawsBalance ?? 0) >= style.price else {
            alertMessage = "You need \(style.price - (userViewModel.user?.pawsBalance ?? 0)) more paws for \(style.name)."
            showingAlert = true
            return
        }

        pendingStyleFileName = style.fileName
        defer { pendingStyleFileName = nil }

        do {
            try await userViewModel.spendPawsBalance(amount: style.price)
            selectedStyleFileName = style.fileName
            ownedStylesCSV = ownedStylesCSV
                .split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
                .union([style.fileName])
                .sorted()
                .joined(separator: ",")
            alertMessage = "Purchased \(style.name) and equipped it on Home."
            showingAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private struct PandaStyle: Identifiable {
        let id = UUID()
        let name: String
        let fileName: String
        let price: Int
        let accent: Color
    }
}

private extension Array where Element == String {
    func union(_ other: [String]) -> [String] {
        Array(Set(self).union(other)).sorted()
    }
}
