import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

public struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    private let badgeColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    public init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Профиль")
                    .font(.slimlyLargeTitle)
                    .tracking(SlimlyTracking.largeTitle)

                libraryCard
                savedCard
                achievementsHeader
                nextAchievementCard
                badges
                proCard
                settings
            }
            .padding(.horizontal, SlimlySpacing.screenHorizontal)
            .padding(.bottom, 6)
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

                Text("Система отдаёт количество файлов и свободное место, но не общий вес медиатеки — поэтому веса здесь нет")
                    .font(.slimlyMicro)
                    .foregroundStyle(SlimlyColor.neutral600)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 13)
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
                    breakdown(value: viewModel.stats.photoCount, caption: "фото")
                    breakdown(value: viewModel.stats.videoCount, caption: "видео")
                    breakdown(value: viewModel.stats.heicConvertedCount, caption: "HEIC→JPEG")
                }
                .padding(.top, 12)
            }
        }
    }

    private func breakdown(value: Int, caption: String) -> some View {
        HStack(spacing: 4) {
            Text(CountFormatter.string(value))
                .font(.system(size: 15, weight: .medium))
            Text(caption)
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral500)
        }
    }

    // MARK: Ачивки

    private var achievementsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Ачивки").font(.slimlySectionTitle)
            Spacer()
            Text(viewModel.earnedCountText)
                .font(.slimlyCaption)
                .foregroundStyle(SlimlyColor.neutral500)
        }
    }

    @ViewBuilder
    private var nextAchievementCard: some View {
        if let next = viewModel.nextAchievement {
            SlimlyCard(padding: EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15)) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Ближайшая: ")
                            .foregroundStyle(SlimlyColor.neutral300)
                            + Text(next.goalDescription)
                            .foregroundStyle(SlimlyColor.text)

                        Spacer(minLength: 8)

                        Text(viewModel.progressText(for: next))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SlimlyColor.accent300)
                    }
                    .font(.slimlyBodySmall)

                    SlimlyProgressBar(value: viewModel.progress(for: next), height: 6)
                        .padding(.top, 10)
                }
            }
        }
    }

    private var badges: some View {
        LazyVGrid(columns: badgeColumns, spacing: 8) {
            ForEach(viewModel.achievements) { achievement in
                badge(achievement, isEarned: viewModel.isEarned(achievement))
            }
        }
    }

    private func badge(_ achievement: Achievement, isEarned: Bool) -> some View {
        let foreground = isEarned ? SlimlyColor.accent200 : SlimlyColor.neutral600

        return VStack(spacing: 7) {
            Text(achievement.glyph)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(foreground)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle().strokeBorder(
                        isEarned ? SlimlyColor.accent : SlimlyColor.neutral800,
                        lineWidth: 1.5
                    )
                )

            Text(achievement.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(foreground)

            Text(achievement.subtitle)
                .font(.slimlyNano)
                .foregroundStyle(SlimlyColor.neutral600)
        }
        .multilineTextAlignment(.center)
        // Строка сетки выравнивается по самой высокой плитке — остальные
        // тянем следом, иначе они «висят» по центру и ряд выглядит рваным.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 14)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
        .background {
            RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                .fill(SlimlyColor.surface)
                .overlay {
                    if isEarned {
                        RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                            .fill(SlimlyColor.accentTint(11))
                    }
                }
        }
        .slimlyElevation(.sm)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isEarned ? "получена" : "не получена")
    }

    // MARK: Pro и настройки

    private var proCard: some View {
        SlimlyCard(padding: EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Squeeze Pro")
                        .font(.system(size: 13.5, weight: .medium))
                    Text("Пакет без лимита · ручные настройки качества")
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Экран пейволла в макете не описан, поэтому «Открыть» пока
                // не ведёт никуда и не притворяется кнопкой.
                Text("Открыть")
                    .font(.slimlyButtonSmall)
                    .foregroundStyle(SlimlyColor.accent200)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
                            .strokeBorder(SlimlyColor.accent, lineWidth: 1)
                    )
            }
        }
    }

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
