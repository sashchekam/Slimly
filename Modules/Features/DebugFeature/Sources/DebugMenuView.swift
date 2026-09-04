import SlimlyDesignSystem
import SwiftUI

/// Сервисный экран, а не часть продукта: здесь подменяют поведение сборки
/// и забирают данные о ней.
///
/// Шапка своя, а не ``SlimlyNavigationBar``: у меню есть заголовок и
/// «Готово» вместо шеврона — это модалка, из неё не возвращаются, её закрывают.
public struct DebugMenuView: View {
    @State
    private var viewModel: DebugMenuViewModel

    public init(viewModel: DebugMenuViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(viewModel.summary)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(viewModel.knobs) { knob in
                        knobCard(knob)
                    }

                    Text("разделы")
                        .slimlyKicker()
                        .padding(.top, 4)

                    sections

                    Text("действия")
                        .slimlyKicker()
                        .padding(.top, 4)

                    actions

                    Text(
                        "Меню открывается тряской устройства и живёт только во внутренних "
                            + "сборках — в App Store его нет."
                    )
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral600)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.top, 4)
                .padding(.bottom, 34)
            }
        }
        .slimlyScreen()
        .slimlyToast(viewModel.toast)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Text("Debug-меню")
                .font(.system(size: 17, weight: .medium))
                .tracking(-0.2)

            SlimlyTagBadge("INTERNAL")

            Spacer(minLength: 12)

            Button("Готово") { viewModel.close() }
                .buttonStyle(SlimlyLinkButtonStyle(font: .system(size: 15, weight: .medium)))
        }
        .frame(minHeight: 44)
        .padding(.horizontal, SlimlySpacing.screenHorizontal)
        .padding(.bottom, 12)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(SlimlyColor.text.opacity(0.07))
                .frame(height: 1)
        }
    }

    private func knobCard(_ knob: DebugMenuViewModel.Knob) -> some View {
        SlimlyCard(padding: EdgeInsets(top: 14, leading: 15, bottom: 15, trailing: 15)) {
            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(knob.title)
                        .font(.system(size: 13, weight: .medium))
                    Text(knob.hint)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SlimlyWrap(spacing: 6, lineSpacing: 6) {
                    ForEach(knob.options) { option in
                        Button {
                            viewModel.select(option, in: knob)
                        } label: {
                            SlimlyChip(option.title, isSelected: option.isSelected, style: .onSurface)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var sections: some View {
        SlimlyRowGroup {
            ForEach(viewModel.sections) { section in
                Button {
                    viewModel.open(section)
                } label: {
                    HStack(spacing: 10) {
                        Text(section.title)
                            .font(.slimlyRowTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(viewModel.value(for: section))
                            .font(.slimlyCaption)
                            .foregroundStyle(SlimlyColor.neutral600)
                        SlimlyIcon(.chevronRight, width: 6)
                            .foregroundStyle(SlimlyColor.neutral600)
                    }
                    .slimlyRow(horizontal: 15, vertical: 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var actions: some View {
        SlimlyRowGroup {
            ForEach(viewModel.actions) { action in
                Button {
                    viewModel.perform(action)
                } label: {
                    HStack(spacing: 10) {
                        Text(action.title)
                            .font(.slimlyRowTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(action.value)
                            .font(.slimlyCaption)
                            .foregroundStyle(SlimlyColor.neutral600)
                    }
                    .slimlyRow(horizontal: 15, vertical: 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
