import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

public struct ResultView: View {
    @State private var viewModel: ResultViewModel

    public init(viewModel: ResultViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary

                SlimlyRowGroup {
                    ForEach(viewModel.results) { CompressionResultRow(result: $0) }
                }

                if let achievement = viewModel.unlockedAchievement {
                    achievementBanner(achievement)
                }

                actions
            }
            .padding(.top, 16)
            .padding(.horizontal, SlimlySpacing.screenHorizontal)
            .padding(.bottom, 4)
        }
        .slimlyScreen()
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("готово").slimlyKicker()

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(viewModel.beforeText)
                    .font(.system(size: 21))
                    .foregroundStyle(SlimlyColor.neutral500)
                    .strikethrough(true, color: SlimlyColor.neutral700)

                SlimlyIcon(.arrowRight, width: 16)
                    .foregroundStyle(SlimlyColor.neutral600)

                Text(viewModel.afterText)
                    .font(.slimlyStatXL)
                    .tracking(SlimlyTracking.statXL)
                    .foregroundStyle(SlimlyColor.accent300)
            }
            .padding(.top, 11)

            Text(viewModel.summaryLine)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral400)
                .padding(.top, 9)

            SlimlyFadingRule().padding(.top, 14)
        }
    }

    private func achievementBanner(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            SlimlyIcon(.trophy, width: 17)
                .foregroundStyle(SlimlyColor.accent300)
                .frame(width: 37, height: 37)
                .overlay(Circle().strokeBorder(SlimlyColor.accent, lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 2) {
                Text("Новая ачивка: «\(achievement.celebration)»")
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)

                Button("Смотреть в профиле") { viewModel.openProfile() }
                    .buttonStyle(SlimlyLinkButtonStyle(color: SlimlyColor.accent300, font: .slimlyCaption))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            SlimlyColor.accentTint(10),
            in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
        )
        .slimlyElevation(.sm)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button("Готово") { viewModel.finish() }
                .buttonStyle(.slimlyOutline)

            if viewModel.showsDeleteAction {
                Button {
                    viewModel.deleteOriginals()
                } label: {
                    VStack(spacing: 0) {
                        Text(viewModel.deleteTitle)
                            .font(.slimlyBodySmall)
                            .foregroundStyle(SlimlyColor.neutral400)
                        Text("iOS покажет свой запрос на удаление")
                            .font(.slimlyCaptionSmall)
                            .foregroundStyle(SlimlyColor.neutral600)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
