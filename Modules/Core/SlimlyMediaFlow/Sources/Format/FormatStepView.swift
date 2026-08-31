import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Общий шаг «в какой формат»: пара «из → в», выбор формата и список файлов.
public struct FormatStepView: View {
    @State private var viewModel: FormatStepViewModel

    public init(viewModel: FormatStepViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    header
                    transitionCard

                    Text("Формат результата").font(.slimlySectionTitle)
                    formats

                    Text(viewModel.config.note)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral600)
                        .fixedSize(horizontal: false, vertical: true)

                    fileList
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SlimlyBottomAction {
                    Button(viewModel.ctaTitle) { viewModel.start() }
                        .buttonStyle(.slimlyPrimary)
                }
            }
        }
        .slimlyScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.config.title)
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.title)
            Text(viewModel.summary)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
        }
    }

    private var transitionCard: some View {
        SlimlyCard {
            HStack(spacing: 12) {
                formatColumn(
                    kicker: "из",
                    value: viewModel.config.sourceFormat,
                    color: SlimlyColor.neutral300
                )

                SlimlyIcon(.arrowRight, width: 18)
                    .foregroundStyle(SlimlyColor.neutral600)

                formatColumn(
                    kicker: "в",
                    value: viewModel.targetTitle,
                    color: SlimlyColor.accent300
                )
            }
        }
    }

    private func formatColumn(kicker: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(kicker).slimlyKicker()
            Text(value)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(color)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formats: some View {
        SlimlyWrap {
            ForEach(viewModel.formats) { format in
                Button {
                    viewModel.select(format)
                } label: {
                    SlimlyChip(format.id, isSelected: viewModel.isSelected(format))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var fileList: some View {
        SlimlyRowGroup {
            ForEach(viewModel.items) { item in
                MediaFileRow(
                    item: item,
                    name: item.fileName,
                    detail: viewModel.detail(for: item),
                    thumbnail: viewModel.thumbnails
                )
            }
        }
    }
}
