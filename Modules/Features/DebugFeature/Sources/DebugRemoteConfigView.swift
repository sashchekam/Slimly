import SlimlyDesignSystem
import SwiftUI

/// Значения удалённого конфига: что приехало с сервера и чем это подменено
/// на этом устройстве.
///
/// Правка идёт в системном алерте, а не в поле внутри строки: поле ввода —
/// единственное на всё приложение, и заводить под него свой контрол ради
/// служебного экрана незачем.
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
        .alert(Text(viewModel.editedTitle), isPresented: $viewModel.isEditing) {
            TextField(L10n.Config.valueField, text: $viewModel.draft)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button(L10n.Config.override) { viewModel.applyEdit() }

            if viewModel.canResetEdit {
                Button(L10n.Config.restore) { viewModel.resetEdit() }
            }

            Button(L10n.Config.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Config.editNote)
        }
    }

    private var values: some View {
        SlimlyRowGroup {
            ForEach(viewModel.entries) { entry in
                Button {
                    viewModel.edit(entry)
                } label: {
                    row(entry)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func row(_ entry: DebugRemoteConfigViewModel.Entry) -> some View {
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

            Text(entry.value)
                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                .foregroundStyle(entry.isOverridden ? SlimlyColor.accent300 : SlimlyColor.neutral400)
                .multilineTextAlignment(.trailing)
                // Длинному значению — половина строки: имя ключа должно
                // остаться читаемым, даже если в значении лежит JSON.
                .frame(maxWidth: 120, alignment: .trailing)

            SlimlyIcon(.chevronRight, width: 6)
                .foregroundStyle(SlimlyColor.neutral600)
                .padding(.top, 3)
        }
        .slimlyRow(horizontal: 15, vertical: 13)
        .contentShape(Rectangle())
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
