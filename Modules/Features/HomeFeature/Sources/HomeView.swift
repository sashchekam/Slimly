import SlimlyDesignSystem
import SwiftUI

/// Главный экран — хаб инструментов. Дальше у всех инструментов один путь:
/// выбор файлов → настройки → итог.
public struct HomeView: View {
    @State
    private var viewModel: HomeViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    public init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar {
                SlimlyCircleButton(
                    icon: .person,
                    accessibilityLabel: L10n.Home.profile
                ) {
                    viewModel.openProfile()
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    greeting
                    grid
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.top, 6)
                .padding(.bottom, 14)
            }
        }
        .slimlyScreen()
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(viewModel.greeting)
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.largeTitle)
            Text(L10n.Home.prompt)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral500)
        }
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    /// Сетка два в ряд: нечётный хвост остаётся полуширинной карточкой,
    /// а не растягивается на всю строку.
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.tools) { tool in
                Button {
                    viewModel.open(tool)
                } label: {
                    ToolCard(tool: tool)
                }
                .buttonStyle(.slimlyPressable)
            }
        }
    }
}

private struct ToolCard: View {
    let tool: HomeTool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SlimlyIcon(tool.icon, width: 24)
                .foregroundStyle(SlimlyColor.neutral300)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.system(size: 14.5, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Text(tool.subtitle)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 17)
        // Высота — по самой высокой карточке ряда, но не меньше макетной:
        // «Сжатие» с короткой подписью не должно быть ниже соседа.
        .frame(maxWidth: .infinity, minHeight: 124, maxHeight: .infinity, alignment: .topLeading)
        .background(
            SlimlyColor.surface,
            in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
        )
        .slimlyElevation(.sm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
