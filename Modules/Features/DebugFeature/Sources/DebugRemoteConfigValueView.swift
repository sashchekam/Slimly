import SlimlyDesignSystem
import SwiftUI

/// Правка одного значения удалённого конфига.
public struct DebugRemoteConfigValueView: View {
    @State
    private var viewModel: DebugRemoteConfigValueViewModel

    @FocusState
    private var isTyping: Bool

    public init(viewModel: DebugRemoteConfigValueViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() }) {
                Button(L10n.Config.format) { viewModel.format() }
                    .buttonStyle(SlimlyLinkButtonStyle(font: .system(size: 15, weight: .medium)))
                    .disabled(!viewModel.canFormat)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    editor

                    if !viewModel.isValid {
                        Text(L10n.Config.invalid)
                            .font(.slimlyCaption)
                            .foregroundStyle(SlimlyColor.accent300)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    actions

                    Text(L10n.Config.editNote)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)

                    if let remotePretty = viewModel.remotePretty {
                        serverValue(remotePretty)
                    }
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 34)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .slimlyScreen()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(L10n.Config.doneTyping) { isTyping = false }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Имя ключа набирают в веб-консоли посимвольно — моноширинный
            // шрифт здесь не украшение, а способ не спутать похожие буквы.
            Text(viewModel.name)
                .font(.system(size: 19, weight: .medium, design: .monospaced))
                .foregroundStyle(SlimlyColor.text)

            Text(viewModel.status)
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var editor: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Config.valueField)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)

                TextEditor(text: $viewModel.draft)
                    .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(SlimlyColor.text)
                    .tint(SlimlyColor.accent300)
                    .scrollContentBackground(.hidden)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(minHeight: 200)
                    .focused($isTyping)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(L10n.Config.override) { viewModel.apply() }
                .buttonStyle(.slimlyPrimary)
                .disabled(!viewModel.isValid)

            if viewModel.isOverridden {
                Button(L10n.Config.restore) { viewModel.restore() }
                    .buttonStyle(.slimlyOutline)
            }
        }
    }

    private func serverValue(_ text: String) -> some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Config.serverValue)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)

                Text(text)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(SlimlyColor.neutral400)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
