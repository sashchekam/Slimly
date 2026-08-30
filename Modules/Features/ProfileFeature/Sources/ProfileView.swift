import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

public struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Профиль")
                        .font(.slimlyLargeTitle)
                        .tracking(SlimlyTracking.largeTitle)

                    libraryCard
                    savedCard
                    settings
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    // MARK: В медиатеке

    private var libraryCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("в медиатеке").slimlyKicker()

                HStack(spacing: 20) {
                    statColumn(value: Text(viewModel.photoCountText), caption: "фото")
                    SlimlyColumnDivider()
                    statColumn(value: Text(viewModel.videoCountText), caption: "видео")
                    SlimlyColumnDivider()
                    statColumn(
                        value: Text(viewModel.freeSpace.value)
                            + Text(" \(viewModel.freeSpace.unit)")
                            .font(.system(size: 13))
                            .foregroundColor(SlimlyColor.neutral400),
                        caption: "свободно"
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            }
        }
    }

    private func statColumn(value: Text, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            value
                .font(.slimlyStatS)
                .tracking(SlimlyTracking.statS)
            Text(caption)
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral500)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Сжато нами

    private var savedCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("сжато нами").slimlyKicker()

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(viewModel.savedText)
                        .font(.slimlyStatM)
                        .tracking(SlimlyTracking.statM)
                        .foregroundStyle(SlimlyColor.accent300)
                    Text("освобождено")
                        .font(.system(size: 12))
                        .foregroundStyle(SlimlyColor.neutral400)
                }
                .padding(.top, 10)

                SlimlyProgressBar(value: viewModel.remainingFraction, height: 8)
                    .padding(.top, 13)

                HStack {
                    Text(viewModel.compressedText)
                    Spacer()
                    Text(viewModel.originalText)
                }
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral500)
                .padding(.top, 8)

                Rectangle()
                    .fill(SlimlyColor.text.opacity(0.09))
                    .frame(height: 1)
                    .padding(.top, 13)

                HStack(spacing: 20) {
                    ForEach(viewModel.breakdown, id: \.caption) { item in
                        HStack(spacing: 4) {
                            Text(item.value)
                                .font(.system(size: 15, weight: .medium))
                            Text(item.caption)
                                .font(.slimlyCaptionSmall)
                                .foregroundStyle(SlimlyColor.neutral500)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: Настройки

    private var settings: some View {
        SlimlyRowGroup {
            ForEach(viewModel.settingsRows) { row in
                HStack(spacing: 10) {
                    Text(row.label)
                        .font(.slimlyBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.value)
                        .font(.system(size: 12))
                        .foregroundStyle(SlimlyColor.neutral500)
                    SlimlyIcon(.chevronRight, width: 6)
                        .foregroundStyle(SlimlyColor.neutral600)
                }
                .slimlyRow(horizontal: 15, vertical: 13)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
