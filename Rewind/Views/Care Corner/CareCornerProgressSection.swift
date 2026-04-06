import SwiftUI

struct CareCornerProgressSection: View {
    @ObservedObject var viewModel: CareCornerViewModel
    let pawsBalance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your rhythm")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                metricCard(title: "Paws", value: pawsBalance, icon: "pawprint.fill", tint: .eliteAccentPrimary)
                metricCard(title: "Challenges", value: viewModel.stats?.totalChallengesCompleted ?? 0, icon: "checkmark.seal.fill", tint: Color(red: 1.0, green: 0.62, blue: 0.25))
            }
        }
    }

    private func metricCard(title: String, value: Int, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
            }

            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}
