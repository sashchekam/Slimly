import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

public struct StatisticsView: View {
    @State
    private var viewModel: StatisticsViewModel

    public init(viewModel: StatisticsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    rangePicker

                    if viewModel.isEmpty {
                        emptyCard
                    } else {
                        operationsCard
                        toolCards
                    }

                    footnote
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    // MARK: Заголовок и срез

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L10n.Statistics.title)
                .font(.slimlyLargeTitle)
                .tracking(SlimlyTracking.largeTitle)
            Text(viewModel.periodText)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral500)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 7) {
            ForEach(viewModel.ranges) { range in
                Button {
                    viewModel.select(range)
                } label: {
                    SlimlyChip(range.title, isSelected: range == viewModel.range, fillsWidth: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Операции по инструментам

    private var operationsCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 13) {
                Text(L10n.Statistics.byTool).slimlyKicker()

                HStack(alignment: .lastTextBaseline, spacing: 9) {
                    Text(viewModel.totalText)
                        .font(.slimlyStatM)
                        .tracking(SlimlyTracking.statM)
                    Text(L10n.Statistics.total)
                        .font(.slimlyBodySmall)
                        .foregroundStyle(SlimlyColor.neutral400)
                }

                SlimlyShareBar(segments: viewModel.shares.map(Self.segment))

                SlimlyWrap(spacing: 16, lineSpacing: 9) {
                    ForEach(viewModel.shares) { share in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Self.color(for: share.id))
                                .frame(width: 7, height: 7)
                            Text(verbatim: "\(share.label) · \(share.percentText)")
                                .font(.slimlyCaptionSmall)
                                .foregroundStyle(SlimlyColor.neutral400)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private static func segment(_ share: StatisticsViewModel.Share) -> SlimlyShareBar.Segment {
        SlimlyShareBar.Segment(
            id: share.id.rawValue,
            share: share.fraction,
            color: color(for: share.id)
        )
    }

    /// Цвета идут по убыванию «громкости» в том же порядке, в каком
    /// инструменты стоят на главной: полоса и легенда читаются как один
    /// список, а не как случайный набор оттенков.
    private static func color(for kind: ProcessingKind) -> Color {
        switch kind {
        case .compression: SlimlyColor.accent500
        case .conversion: SlimlyColor.accent700
        case .audioExtraction: SlimlyColor.neutral600
        case .scan: SlimlyColor.neutral800
        }
    }

    // MARK: Карточка инструмента

    private var toolCards: some View {
        VStack(spacing: 9) {
            ForEach(viewModel.cards) { card in
                toolCard(card)
            }
        }
    }

    private func toolCard(_ card: StatisticsViewModel.Card) -> some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 11) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(card.title)
                            .font(.slimlySectionTitle)
                        Text(card.note)
                            .font(.slimlyCaption)
                            .foregroundStyle(SlimlyColor.neutral500)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(card.countText)
                            .font(.system(size: 22, weight: .medium))
                            .tracking(-0.5)
                            .foregroundStyle(
                                card.isLeading ? SlimlyColor.accent200 : SlimlyColor.neutral100
                            )
                        Text(card.unit)
                            .font(.slimlyMicro)
                            .foregroundStyle(SlimlyColor.neutral500)
                    }
                }

                SlimlySparkline(values: card.spark, tint: card.isLeading ? .accent : .neutral)

                facts(card.facts)
            }
        }
    }

    private func facts(_ facts: [StatisticsViewModel.Fact]) -> some View {
        // Просвет в один пункт вместо разделителей — тот же приём, что
        // в списке строк: линия получается сплошной внутри блока.
        HStack(spacing: 1) {
            ForEach(facts) { fact in
                VStack(alignment: .leading, spacing: 4) {
                    Text(fact.value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SlimlyColor.neutral100)
                    Text(fact.label)
                        .font(.slimlyNano)
                        .foregroundStyle(SlimlyColor.neutral500)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SlimlyColor.surfaceInset)
                .accessibilityElement(children: .combine)
            }
        }
        .background(SlimlyColor.text.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.sm, style: .continuous))
    }

    // MARK: Пустой срез и подпись

    private var emptyCard: some View {
        SlimlyCard {
            Text(viewModel.emptyText)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral400)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footnote: some View {
        Text(L10n.Statistics.privacy)
            .font(.slimlyCaptionSmall)
            .foregroundStyle(SlimlyColor.neutral600)
            .fixedSize(horizontal: false, vertical: true)
    }
}
