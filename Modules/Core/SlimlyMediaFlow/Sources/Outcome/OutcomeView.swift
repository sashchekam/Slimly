import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

/// Итог обработки: что получилось, из чего, и что с этим делать дальше.
public struct OutcomeView: View {
    @State
    private var viewModel: OutcomeViewModel

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

                    if viewModel.showsShareAll {
                        shareAll
                    }

                    if let hint = viewModel.previewHint {
                        note(hint).padding(.top, -8)
                    }

                    if viewModel.showsSaveNote {
                        note(viewModel.saveNote)
                    }

                    if !viewModel.failures.isEmpty {
                        failureList
                    }

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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
        }
        .slimlyScreen()
        // Возвращаться некуда: позади — экран уже закончившейся обработки.
        .backSwipeDisabled()
    }

    /// Тост живёт над кнопками, а не у нижнего края: общий `slimlyToast`
    /// накрыл бы собой действие, которое его и вызвало.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            if let toast = viewModel.toast {
                SlimlyToast(toast, icon: viewModel.isSaved ? .check : nil)
                    .padding(.horizontal, SlimlySpacing.screenHorizontal)
                    .padding(.bottom, 12)
                    .transition(.slimlyToast)
            }

            SlimlyBottomAction {
                VStack(spacing: 10) {
                    if viewModel.showsSaveButton {
                        saveButton
                            // Кнопка не пропадает рывком, а сжимается вверх,
                            // пока на её месте всплывает тост: это один жест,
                            // а не два независимых.
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }

                    // После сохранения главным действием остаётся выход,
                    // и акцент переезжает на него.
                    Button("Готово") { viewModel.finish() }
                        .buttonStyle(SlimlyOutlineButtonStyle(emphasis: viewModel.isSaved ? .tinted : .plain))
                }
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.toast)
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: viewModel.isSaved)
    }

    /// Главное действие экрана: до нажатия результат существует только
    /// внутри приложения, и наружу его выносит именно эта кнопка. Сделав своё
    /// дело, она уходит — подтверждает тост, а место назначения остаётся
    /// написанным в подписи под списком.
    private var saveButton: some View {
        Button {
            viewModel.save()
        } label: {
            HStack(spacing: 9) {
                if viewModel.isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    SlimlyIcon(saveIcon, width: 17)
                }

                Text(viewModel.saveTitle)
            }
        }
        .buttonStyle(.slimlyPrimary)
        .disabled(viewModel.isSaving)
    }

    private var saveIcon: SlimlyIcon.Kind {
        viewModel.destination == .photoLibrary ? .gallery : .folder
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
                resultRow(result)
            }
        }
    }

    /// Строка результата — две зоны сразу: тап по содержимому открывает
    /// просмотр, тап по иконке справа — системную шторку. Поэтому строка
    /// не обёрнута в одну кнопку: вложенная кнопка в SwiftUI не нажимается.
    private func resultRow(_ result: ProcessingResult) -> some View {
        HStack(spacing: 12) {
            // Кнопкой содержимое становится, только если просмотр есть:
            // выключенная кнопка гасила бы строку там, где смотреть нечего.
            if viewModel.canPreview(result) {
                Button {
                    viewModel.openPreview(result)
                } label: {
                    label(for: result, showsPreview: true)
                        // Без своей формы кнопка ловит нажатие только по самим
                        // тексту и картинке — промежутки между ними проваливались
                        // бы мимо, хотя выглядят частью той же строки.
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                label(for: result, showsPreview: false)
            }

            if let url = viewModel.shareURL(for: result) {
                ShareLink(item: url) {
                    SlimlyIcon(.share, width: 17)
                        .foregroundStyle(SlimlyColor.accent300)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Поделиться файлом \(viewModel.name(for: result))")
                // Иконка тянет вокруг себя область нажатия, а выглядеть
                // должна прижатой к краю строки, как остальные значки.
                .padding(.vertical, -4)
                .padding(.trailing, -3)
            }
        }
        .slimlyRow()
    }

    private func label(for result: ProcessingResult, showsPreview: Bool) -> some View {
        MediaFileLabel(
            item: result.item,
            name: viewModel.name(for: result),
            detail: viewModel.detail(for: result),
            thumbnail: viewModel.thumbnails,
            delta: viewModel.delta(for: result),
            showsPreview: showsPreview
        )
    }

    /// Одна шторка на все результаты: по отдельности их пришлось бы
    /// отправлять столько же раз, сколько файлов в очереди.
    private var shareAll: some View {
        ShareLink(items: viewModel.shareURLs) {
            HStack(spacing: 9) {
                SlimlyIcon(.share, width: 17)
                    .foregroundStyle(SlimlyColor.accent300)

                Text(viewModel.shareAllTitle)
                    .font(.slimlyButton)
                    .foregroundStyle(SlimlyColor.neutral100)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                SlimlyColor.surface,
                in: RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
            )
            .slimlyElevation(.sm)
            .contentShape(RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous))
        }
        .buttonStyle(.slimlyPressable)
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
