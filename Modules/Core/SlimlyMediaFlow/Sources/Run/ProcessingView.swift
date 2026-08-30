import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Экран обработки: кольцо общего прогресса и очередь файлов.
/// Возврата отсюда нет — только «Отменить», иначе работа продолжалась бы
/// без экрана, который её показывает.
public struct ProcessingView: View {
    @State private var viewModel: ProcessingViewModel

    public init(viewModel: ProcessingViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar()

            ScrollView {
                VStack(spacing: 22) {
                    ring
                    queue

                    Button("Отменить") { viewModel.cancel() }
                        .buttonStyle(.slimlyQuietLink)
                        .padding(6)
                        .frame(maxWidth: .infinity)

                    Text("Идёт, пока приложение открыто — как экспорт в Фото")
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral600)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 22)
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
        // Работа идёт, пока открыт этот экран, — смахнуть его нельзя.
        .backSwipeDisabled()
        .task { await viewModel.run() }
    }

    private var ring: some View {
        VStack(spacing: 15) {
            SlimlyProgressRing(value: viewModel.progress.overall) {
                VStack(spacing: 3) {
                    Text(viewModel.percentText)
                        .font(.slimlyStatRing)
                        .tracking(SlimlyTracking.statM)
                    Text(viewModel.runWord)
                        .font(.system(size: 10))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(SlimlyColor.neutral500)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.runWord)
            .accessibilityValue(viewModel.percentText)

            Text(viewModel.summaryLine)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
                .multilineTextAlignment(.center)
        }
    }

    private var queue: some View {
        SlimlyRowGroup {
            ForEach(viewModel.items) { item in
                HStack(spacing: 12) {
                    MediaThumbnail(item: item, pointSize: 29, load: viewModel.thumbnails)
                        .frame(width: 29, height: 29)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.fileName)
                            .font(.slimlyBodySmall)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        SlimlyProgressBar(
                            value: viewModel.fraction(for: item),
                            height: 3,
                            fill: .solid
                        )
                        .padding(.top, 7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(viewModel.state(for: item))
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .frame(minWidth: 42, alignment: .trailing)
                }
                .slimlyRow(vertical: 11)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
