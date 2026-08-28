import SwiftUI
import SlimlyDesignSystem

public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: SlimlySpacing.m) {
            Spacer()
            Button("Выйти") { Task { await viewModel.signOut() } }
                .buttonStyle(.slimlySecondary)
        }
        .padding(SlimlySpacing.l)
        .background(SlimlyColor.background)
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Готово") { viewModel.close() }
            }
        }
    }
}
