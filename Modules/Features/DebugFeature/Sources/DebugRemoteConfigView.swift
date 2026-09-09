import SlimlyDesignSystem
import SwiftUI

/// Значения удалённого конфига: что приехало с сервера и чем это подменено
/// на этом устройстве.
///
/// Строка показывает значение целиком — объект в ней разложен по строкам:
/// хвост вида `{"scan_pages"…` в углу не говорит ни о чём. Правят значение
/// на своём экране, куда строка и ведёт.
public struct DebugRemoteConfigView: View {
    @State
    private var viewModel: DebugRemoteConfigViewModel

    public init(viewModel: DebugRemoteConfigViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() }) {
                Button(L10n.Config.refresh) {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(SlimlyLinkButtonStyle(font: .system(size: 15, weight: .medium)))
                .disabled(viewModel.isRefreshing)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(verbatim: "Remote Config")
                        .font(.slimlyTitle)
                        .tracking(SlimlyTracking.title)

                    Text(L10n.Config.note)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.entries.isEmpty {
                        emptyCard
                    } else {
                        values
                    }

                    if viewModel.hasOverrides {
                        Button(L10n.Config.clearAll) { viewModel.resetAll() }
                            .buttonStyle(.slimlyOutline)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 34)
            }
        }
        .slimlyScreen()
        .slimlyToast(viewModel.toast)
        // Подмену ставят и снимают на экране значения, а рассказывает
        // о ней эта строка — на возврате список перечитывают.
        .onAppear { viewModel.reload() }
    }

    private var values: some View {
        SlimlyRowGroup {
            ForEach(viewModel.entries) { entry in
                Button {
                    viewModel.open(entry)
                } label: {
                    row(entry)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func row(_ entry: DebugRemoteConfigViewModel.Entry) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    // Моноширинный — как у метки INTERNAL: имя ключа набирают
                    // в веб-консоли посимвольно, и подчёркнутая служебность
                    // тут уместнее ровного текста.
                    Text(entry.id)
                        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(SlimlyColor.text)

                    Text(entry.source)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral600)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Число и флаг помещаются в угол строки, объект — нет:
                // он идёт под именем ключа, во всю ширину.
                if !entry.isObject {
                    Text(entry.value)
                        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(value(of: entry))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120, alignment: .trailing)
                }

                SlimlyIcon(.chevronRight, width: 6)
                    .foregroundStyle(SlimlyColor.neutral600)
                    .padding(.top, 3)
            }

            if let prettyValue = entry.prettyValue {
                Text(prettyValue)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(value(of: entry))
                    // Длинный объект обрывается: строка списка показывает,
                    // что в нём, а не заменяет собой экран значения.
                    .lineLimit(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(
                        SlimlyColor.surfaceSunken,
                        in: RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
                    )
            }
        }
        .slimlyRow(horizontal: 15, vertical: 13)
        .contentShape(Rectangle())
    }

    /// Подменённое значение — акцентом: в списке из десятка ключей взглядом
    /// ищут именно то, что трогали руками.
    private func value(of entry: DebugRemoteConfigViewModel.Entry) -> Color {
        entry.isOverridden ? SlimlyColor.accent300 : SlimlyColor.neutral400
    }

    private var emptyCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Config.empty)
                    .font(.system(size: 13, weight: .medium))

                Text(L10n.Config.emptyNote)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
