import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

public struct ProfileView: View {
    @State
    private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Profile.title)
                        .font(.slimlyLargeTitle)
                        .tracking(SlimlyTracking.largeTitle)

                    libraryCard
                    savedCard
                    usageCard
                    settings
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
        .slimlyToast(viewModel.toast)
        .task { await viewModel.load() }
    }

    // MARK: В медиатеке

    private var libraryCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.Profile.library).slimlyKicker()

                HStack(spacing: 20) {
                    statColumn(
                        value: Text(viewModel.photoCountText),
                        caption: L10n.Unit.photos
                    )
                    SlimlyColumnDivider()
                    statColumn(
                        value: Text(viewModel.videoCountText),
                        caption: L10n.Unit.videos
                    )
                    SlimlyColumnDivider()
                    statColumn(
                        value: Text(viewModel.freeSpace.value)
                            + Text(verbatim: " \(viewModel.freeSpace.unit)")
                            .font(.system(size: 13))
                            .foregroundColor(SlimlyColor.neutral400),
                        caption: L10n.Profile.free
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
                Text(L10n.Profile.compressed).slimlyKicker()

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(viewModel.savedText)
                        .font(.slimlyStatM)
                        .tracking(SlimlyTracking.statM)
                        .foregroundStyle(SlimlyColor.accent300)
                    Text(L10n.Fact.freed)
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

    // MARK: Чем пользовались

    private var usageCard: some View {
        SlimlyCard(padding: EdgeInsets(top: 15, leading: 16, bottom: 13, trailing: 16)) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 10) {
                    Text(L10n.Profile.usage)
                        .slimlyKicker()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(viewModel.usageCaption)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral500)
                }

                LazyVGrid(columns: Self.usageColumns, spacing: 8) {
                    ForEach(viewModel.usage) { tile in
                        Button {
                            viewModel.openStatistics(from: .tile)
                        } label: {
                            usageTile(tile)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                    }
                }

                Button {
                    viewModel.openStatistics(from: .link)
                } label: {
                    HStack(spacing: 7) {
                        Text(L10n.Profile.allStatistics)
                        SlimlyIcon(.chevronRight, width: 6)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SlimlyLinkButtonStyle(font: .slimlyButtonSmall))
            }
        }
    }

    private static let usageColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private func usageTile(_ tile: ProfileViewModel.UsageTile) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .lastTextBaseline, spacing: 7) {
                Text(tile.countText)
                    .font(.system(size: 20, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(tile.isLeading ? SlimlyColor.accent200 : SlimlyColor.neutral100)
                Text(tile.unit)
                    .font(.slimlyMicro)
                    .foregroundStyle(SlimlyColor.neutral500)
            }

            Text(tile.title)
                .font(.slimlyCaption)
                .foregroundStyle(SlimlyColor.neutral300)
                .frame(maxWidth: .infinity, alignment: .leading)

            SlimlyProgressBar(
                value: tile.share,
                height: 3,
                fill: tile.isLeading ? .solid : .muted
            )
        }
        .padding(EdgeInsets(top: 12, leading: 13, bottom: 11, trailing: 13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            SlimlyColor.background,
            in: RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
                .strokeBorder(SlimlyColor.text.opacity(0.08), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    // MARK: Настройки

    private var settings: some View {
        SlimlyRowGroup {
            ForEach(viewModel.settingsRows) { row in
                Button {
                    viewModel.tap(row)
                } label: {
                    settingsRow(row)
                }
                .buttonStyle(.plain)
                .disabled(!row.isTappable)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func settingsRow(_ row: ProfileViewModel.SettingsRow) -> some View {
        HStack(spacing: 10) {
            Text(row.label)
                .font(.slimlyBody)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.value)
                .font(.system(size: 12))
                .foregroundStyle(SlimlyColor.neutral500)
            // Шеврон одинаковый у всех строк: он часть ритма списка,
            // а не обещание перехода. Спрятать его у строки версии значило бы
            // подсветить ту единственную, которая куда-то ведёт.
            SlimlyIcon(.chevronRight, width: 6)
                .foregroundStyle(SlimlyColor.neutral600)
        }
        .slimlyRow(horizontal: 15, vertical: 13)
        .contentShape(Rectangle())
    }
}
