import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

public struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlimlySpacing.m) {
            if let profile = viewModel.profile {
                LabeledContent("Имя", value: profile.name)
                LabeledContent("Сейчас", value: WeightFormatter.string(profile.currentWeight))
                LabeledContent("Цель", value: WeightFormatter.string(profile.goalWeight))
            } else {
                ProgressView()
            }
            Spacer()
        }
        .font(.slimlySubtitle)
        .padding(SlimlySpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlimlyColor.background)
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
