import SlimlyDesignSystem
import SwiftUI

/// Журнал аналитики: что ушло наружу, когда и с какими параметрами.
///
/// Экран отвечает на вопрос, на который веб-консоль отвечает через сутки:
/// ушло ли событие вообще и то ли в нём лежит. Ошибаются обычно в параметрах,
/// поэтому они здесь рядом с именем, а не в отдельном отчёте.
public struct DebugAnalyticsView: View {
    @State
    private var viewModel: DebugAnalyticsViewModel

    public init(viewModel: DebugAnalyticsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() }) {
                HStack(spacing: 16) {
                    Button(L10n.Analytics.copy) { viewModel.copyAll() }
                    Button(L10n.Analytics.clear) { viewModel.clear() }
                }
                .buttonStyle(SlimlyLinkButtonStyle(font: .system(size: 15, weight: .medium)))
                .disabled(viewModel.isEmpty)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    let entries = viewModel.entries

                    Text(L10n.Menu.analytics)
                        .font(.slimlyTitle)
                        .tracking(SlimlyTracking.title)

                    Text(L10n.Analytics.note(viewModel.capacity))
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)

                    if !viewModel.scopes.isEmpty {
                        scopes
                    }

                    if entries.isEmpty {
                        emptyCard
                    } else {
                        list(entries)
                    }
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 34)
            }
        }
        .slimlyScreen()
        .slimlyToast(viewModel.toast)
    }

    /// Фильтр по префиксу модуля: за один флоу событий набирается несколько
    /// десятков, и своё среди чужих глазами уже не выхватить.
    private var scopes: some View {
        SlimlyWrap(spacing: 6, lineSpacing: 6) {
            chip(L10n.Analytics.all, scope: nil)

            ForEach(viewModel.scopes, id: \.self) { scope in
                chip(scope, scope: scope)
            }
        }
    }

    private func chip(_ title: String, scope: String?) -> some View {
        Button {
            viewModel.select(scope)
        } label: {
            SlimlyChip(title, isSelected: viewModel.isSelected(scope))
        }
        .buttonStyle(.plain)
    }

    private func list(_ entries: [DebugAnalyticsViewModel.Entry]) -> some View {
        SlimlyRowGroup {
            ForEach(entries) { entry in
                Button {
                    viewModel.toggle(entry)
                } label: {
                    row(entry)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func row(_ entry: DebugAnalyticsViewModel.Entry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                // Моноширинный — как у ключей конфига: имя события сверяют
                // с реестром посимвольно, и подчёркнутая служебность тут
                // уместнее ровного текста.
                Text(entry.name)
                    .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(entry.time)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral600)
                    .monospacedDigit()
            }

            if viewModel.isExpanded(entry) {
                parameters(entry)
            } else if !entry.summary.isEmpty {
                HStack(spacing: 8) {
                    Text(entry.summary)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if entry.isExpandable {
                        SlimlyIcon(.chevronDown, width: 9)
                            .foregroundStyle(SlimlyColor.neutral600)
                    }
                }
            }
        }
        .slimlyRow(horizontal: 15, vertical: 12)
        .contentShape(Rectangle())
    }

    private func parameters(_ entry: DebugAnalyticsViewModel.Entry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.parameters) { parameter in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(parameter.name)
                        .foregroundStyle(SlimlyColor.neutral500)

                    Text(parameter.value)
                        .foregroundStyle(SlimlyColor.neutral300)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 11.5, design: .monospaced))
            }
        }
        .padding(.top, 1)
    }

    private var emptyCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Analytics.empty)
                    .font(.system(size: 13, weight: .medium))

                Text(L10n.Analytics.emptyNote)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
