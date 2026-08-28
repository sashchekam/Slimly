import SwiftUI
import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation
import HomeFeatureInterface

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: SlimlySpacing.l) {
            VStack(spacing: SlimlySpacing.xs) {
                Text("Привет, \(viewModel.profile?.name ?? "…")")
                    .font(.slimlyTitle)
                    .foregroundStyle(SlimlyColor.textPrimary)

                if let profile = viewModel.profile {
                    Text(WeightFormatter.progress(from: profile.currentWeight, to: profile.goalWeight))
                        .font(.slimlySubtitle)
                        .foregroundStyle(SlimlyColor.textSecondary)
                }
            }

            Spacer()

            // TODO: здесь появятся реальные экраны дневника — сейчас это каркас,
            // на котором проверяется навигация: push, модалка, диплинк.
            VStack(spacing: SlimlySpacing.s) {
                Button("Профиль") { viewModel.openProfile() }
                    .buttonStyle(.slimlyPrimary)

                Button("Настройки") { viewModel.openSettings() }
                    .buttonStyle(.slimlySecondary)
            }
        }
        .padding(SlimlySpacing.l)
        .background(SlimlyColor.background)
        .navigationTitle("Slimly")
        .task { await viewModel.load() }
    }
}
