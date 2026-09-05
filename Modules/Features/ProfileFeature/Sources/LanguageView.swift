import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

public struct LanguageView: View {
    @State
    private var viewModel: LanguageViewModel

    public init(viewModel: LanguageViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    deviceCard
                    manualList

                    Text(viewModel.footnote)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L10n.Language.title)
                .font(.slimlyLargeTitle)
                .tracking(SlimlyTracking.largeTitle)
            // Обещание в макете — «меняется сразу»; пока строки берёт система,
            // а не приложение, честнее назвать момент, когда язык сменится.
            Text(L10n.Language.note)
                .font(.system(size: 12))
                .foregroundStyle(SlimlyColor.neutral500)
        }
    }

    // MARK: Как в телефоне

    /// Отдельно от списка, а не первой его строкой: это не одиннадцатый язык,
    /// а отказ выбирать язык руками.
    private var deviceCard: some View {
        Button {
            viewModel.select(nil)
        } label: {
            HStack(spacing: 12) {
                SlimlyIcon(.phone, width: 20)
                    .foregroundStyle(viewModel.followsDevice ? SlimlyColor.accent200 : SlimlyColor.neutral400)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Language.system)
                        .font(.slimlyRowTitle)
                    Text(viewModel.deviceNote)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                checkmark(viewModel.followsDevice)
            }
            .padding(EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15))
            .background(
                viewModel.followsDevice ? SlimlyColor.accent900 : SlimlyColor.surface,
                in: cardShape
            )
            .overlay {
                cardShape.strokeBorder(
                    viewModel.followsDevice ? SlimlyColor.accent600 : SlimlyColor.text.opacity(0.09),
                    lineWidth: 1
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(viewModel.followsDevice ? .isSelected : [])
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
    }

    // MARK: Выбрать вручную

    private var manualList: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(L10n.Language.manual)
                .slimlyKicker()
                .padding(.horizontal, 2)

            SlimlyRowGroup {
                ForEach(viewModel.rows) { row in
                    Button {
                        viewModel.select(row.id)
                    } label: {
                        languageRow(row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(row.isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func languageRow(_ row: LanguageViewModel.Row) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.nativeName)
                    .font(.slimlyRowTitle)
                    .foregroundStyle(row.isSelected ? SlimlyColor.accent200 : SlimlyColor.text)
                Text(row.caption)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Код языка моноширинным: десять кодов выстраиваются в колонку
            // и перестают спорить с названиями за внимание.
            Text(verbatim: row.code)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .tracking(0.76)
                .foregroundStyle(SlimlyColor.neutral600)

            checkmark(row.isSelected)
        }
        .slimlyRow(
            horizontal: 15,
            vertical: 12,
            fill: row.isSelected ? SlimlyColor.surfaceInset : SlimlyColor.surface
        )
        .contentShape(Rectangle())
    }

    /// Место под галочку занято всегда: иначе выбор сдвигал бы строку,
    /// и список дёргался бы от каждого нажатия.
    private func checkmark(_ isVisible: Bool) -> some View {
        SlimlyIcon(.check, width: 12)
            .foregroundStyle(SlimlyColor.accent)
            .opacity(isVisible ? 1 : 0)
    }
}
