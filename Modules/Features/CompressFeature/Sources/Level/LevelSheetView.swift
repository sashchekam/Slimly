import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation
import SwiftUI

/// Шторка «Степень сжатия»: ползунок, оценка веса и запуск.
public struct LevelSheetView: View {
    @State
    private var viewModel: LevelSheetViewModel

    public init(viewModel: LevelSheetViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        SlimlySheetScaffold(
            title: L10n.Level.title,
            onCancel: { viewModel.cancel() }
        ) {
            VStack(spacing: 18) {
                slider
                estimate

                Button(viewModel.ctaTitle) { viewModel.start() }
                    .buttonStyle(.slimlyPrimary)
            }
        }
        .sheetHeight(420)
    }

    private var slider: some View {
        VStack(spacing: 11) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.presets.enumerated()), id: \.element) { index, preset in
                    Button {
                        viewModel.select(preset)
                    } label: {
                        Text(preset.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(
                                viewModel.isNearest(preset)
                                    ? SlimlyColor.accent200
                                    : SlimlyColor.neutral500
                            )
                            .frame(maxWidth: .infinity, alignment: alignment(at: index))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SlimlyLevelSlider.edgeInset)

            SlimlyLevelSlider(value: $viewModel.level.value, stops: viewModel.presets.count)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(viewModel.presetSummary)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text(viewModel.deltaText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SlimlyColor.accent300)
            }
        }
    }

    /// Крайние подписи прижаты к концам шкалы, средняя — по центру:
    /// так подпись стоит над своей засечкой, а не над серединой колонки.
    private func alignment(at index: Int) -> Alignment {
        switch index {
        case 0: .leading
        case viewModel.presets.count - 1: .trailing
        default: .center
        }
    }

    private var estimate: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(viewModel.beforeText)
                    .font(.system(size: 19))
                    .foregroundStyle(SlimlyColor.neutral500)
                    .strikethrough(true, color: SlimlyColor.neutral700)

                SlimlyIcon(.arrowRight, width: 16)
                    .foregroundStyle(SlimlyColor.neutral600)

                Text(verbatim: "≈ \(viewModel.afterText)")
                    .font(.system(size: 29, weight: .medium))
                    .tracking(-0.8)
                    .foregroundStyle(SlimlyColor.accent300)
            }

            SlimlyProgressBar(value: viewModel.remainingFraction, height: 7)
                .padding(.top, 13)
                .animation(.easeOut(duration: 0.16), value: viewModel.remainingFraction)

            Text(L10n.Level.estimate(viewModel.savedText))
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral600)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            SlimlyColor.text.opacity(0.045),
            in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
        )
    }
}
