import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Итог обработки: что получилось, из чего, и что с этим делать дальше.
public struct OutcomeView: View {
    @State private var viewModel: OutcomeViewModel

    public init(viewModel: OutcomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summary

                    if !viewModel.results.isEmpty {
                        fileList
                    }

                    if viewModel.allowsComparison, !viewModel.results.isEmpty {
                        note("Нажмите файл, чтобы сравнить до и после")
                            .padding(.top, -8)
                    }

                    if let destination = viewModel.destinationNote {
                        note(destination).padding(.top, -8)
                    }

                    if !viewModel.failures.isEmpty {
                        failureList
                    }

                    Button("Готово") { viewModel.finish() }
                        .buttonStyle(.slimlyOutline)

                    if viewModel.showsDeleteOriginals {
                        deleteOriginals
                    }

                    if let message = viewModel.deletionMessage {
                        note(message)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 4)
            }
        }
        .slimlyScreen()
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.kicker).slimlyKicker()

            if !viewModel.results.isEmpty {
                headline.padding(.top, 11)
            }

            Text(viewModel.summary)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral400)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)

            SlimlyFadingRule().padding(.top, 14)
        }
    }

    private var headline: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if viewModel.showsSizeHeadline {
                Text(viewModel.beforeText)
                    .font(.system(size: 21))
                    .foregroundStyle(SlimlyColor.neutral500)
                    .strikethrough(true, color: SlimlyColor.neutral700)
            } else {
                Text(viewModel.sourceFormat)
                    .font(.system(size: 21))
                    .foregroundStyle(SlimlyColor.neutral500)
            }

            SlimlyIcon(.arrowRight, width: 16)
                .foregroundStyle(SlimlyColor.neutral600)

            if viewModel.showsSizeHeadline {
                Text(viewModel.afterText)
                    .font(.slimlyStatXL)
                    .tracking(SlimlyTracking.statXL)
                    .foregroundStyle(SlimlyColor.accent300)
            } else {
                Text(viewModel.targetFormat)
                    .font(.slimlyStatM)
                    .tracking(SlimlyTracking.statM)
                    .foregroundStyle(SlimlyColor.accent300)
            }
        }
    }

    private var fileList: some View {
        SlimlyRowGroup {
            ForEach(viewModel.results) { result in
                Button {
                    viewModel.openComparison(result)
                } label: {
                    MediaFileRow(
                        item: result.item,
                        name: viewModel.name(for: result),
                        detail: viewModel.detail(for: result),
                        thumbnail: viewModel.thumbnails,
                        delta: viewModel.delta(for: result),
                        showsComparison: viewModel.canCompare(result)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCompare(result))
            }
        }
    }

    /// Отказы показываем списком рядом с готовыми файлами: пользователю важно,
    /// какой именно файл не прошёл и почему, а не общее «что-то пошло не так».
    private var failureList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let summary = viewModel.failureSummary {
                Text(summary)
                    .font(.slimlySectionTitle)
            }

            SlimlyRowGroup {
                ForEach(viewModel.failures) { failure in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(failure.item.fileName)
                            .font(.slimlyBodySmall)
                            .foregroundStyle(SlimlyColor.neutral300)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(failure.message)
                            .font(.slimlyCaptionSmall)
                            .foregroundStyle(SlimlyColor.neutral500)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .slimlyRow()
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var deleteOriginals: some View {
        Button {
            viewModel.deleteOriginals()
        } label: {
            HStack(spacing: 12) {
                SlimlyIcon(.trash, width: 19)
                    .foregroundStyle(SlimlyColor.neutral400)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Удалить оригиналы")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SlimlyColor.neutral200)
                    Text(viewModel.deleteSubtitle)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isDeleting {
                    ProgressView().controlSize(.small)
                } else {
                    SlimlyIcon(.chevronRight, width: 6)
                        .foregroundStyle(SlimlyColor.neutral600)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                SlimlyColor.surface,
                in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
            )
            .slimlyElevation(.sm)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isDeleting)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.slimlyCaptionSmall)
            .foregroundStyle(SlimlyColor.neutral600)
            .fixedSize(horizontal: false, vertical: true)
    }
}
