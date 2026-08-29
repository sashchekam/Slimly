import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

public struct SetupView: View {
    @State private var viewModel: SetupViewModel

    public init(viewModel: SetupViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                backButton
                title
                presets
                estimateCard
                switches
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
        .slimlyScreen()
    }

    private var backButton: some View {
        Button {
            viewModel.goBack()
        } label: {
            HStack(spacing: 6) {
                SlimlyIcon(.chevronLeft, width: 7)
                Text("Назад")
            }
        }
        .buttonStyle(.slimlyLink)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Как сжимать")
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.title)
            Text(viewModel.summary)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
        }
    }

    private var presets: some View {
        VStack(spacing: 7) {
            ForEach(CompressionPreset.allCases) { preset in
                Button {
                    viewModel.select(preset)
                } label: {
                    presetCard(preset)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func presetCard(_ preset: CompressionPreset) -> some View {
        let isActive = viewModel.options.preset == preset

        return SlimlyCard(padding: EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 15)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(preset.title).font(.slimlySectionTitle)
                    Spacer(minLength: 0)
                    Text(viewModel.estimate(for: preset))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SlimlyColor.accent300)
                }
                Text(preset.summary)
                    .font(.slimlyCaption)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                    .strokeBorder(SlimlyColor.accent, lineWidth: 1.5)
            }
        }
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private var estimateCard: some View {
        SlimlyCard(padding: EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("будет").slimlyKicker()

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(viewModel.originalText)
                        .font(.slimlyStatStruck)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .strikethrough(true, color: SlimlyColor.neutral700)

                    SlimlyIcon(.arrowRight, width: 16)
                        .foregroundStyle(SlimlyColor.neutral600)

                    Text("≈ \(viewModel.estimatedText)")
                        .font(.slimlyTitle)
                        .tracking(SlimlyTracking.largeTitle)
                        .foregroundStyle(SlimlyColor.accent300)
                }
                .padding(.top, 11)

                SlimlyProgressBar(value: viewModel.remainingFraction, height: 7)
                    .padding(.top, 13)

                Text("Оценка по битрейту. Точная цифра — после обработки.")
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral600)
                    .padding(.top, 9)
            }
        }
    }

    private var switches: some View {
        SlimlyRowGroup {
            switchRow(
                title: "Оставить оригинал",
                hint: "Удалить предложим после результата",
                isOn: $viewModel.options.keepsOriginals
            )
            switchRow(
                title: "Альбом «Сжатые»",
                hint: "Копии складываем в свой альбом",
                isOn: $viewModel.options.savesToAlbum
            )
            switchRow(
                title: "HEIC → JPEG",
                hint: "Для совместимости; вес почти не меняет",
                isOn: $viewModel.options.convertsHEICToJPEG
            )
        }
    }

    private func switchRow(title: String, hint: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.slimlyRowTitle)
                Text(hint)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
        }
        .toggleStyle(.slimly)
        .slimlyRow(horizontal: 15)
    }
}
