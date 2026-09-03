import SlimlyDesignSystem
import SwiftUI

/// Вводный тур: четыре инструмента приложения, по одному на шаг.
///
/// Это корневой экран первого запуска, а не модалка поверх приложения:
/// возврата из него нет, и последний шаг меняет корень на главный экран.
public struct OnboardingView: View {
    @State
    private var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            OnboardingBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
                actions
            }
        }
        .foregroundStyle(SlimlyColor.text)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.45), value: viewModel.pageIndex)
    }

    /// Шкала шагов и выход. Кнопки «назад» нет: шаг назад в туре никому
    /// не нужен, а крестик ведёт туда же, куда и последний шаг.
    private var header: some View {
        HStack(spacing: 12) {
            steps

            Button {
                viewModel.skip()
            } label: {
                SlimlyIcon(.close, width: 12)
                    .foregroundStyle(SlimlyColor.neutral300)
                    .frame(width: 30, height: 30)
                    .background(SlimlyColor.text.opacity(0.09), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Закрыть")
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
    }

    private var steps: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.pages.indices, id: \.self) { index in
                let isCurrent = index == viewModel.pageIndex

                Capsule()
                    .fill(isCurrent ? SlimlyColor.accent : SlimlyColor.neutral800)
                    .frame(width: isCurrent ? 30 : 14, height: 6)
            }
        }
        .padding(.leading, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel("Шаг \(viewModel.pageIndex + 1) из \(viewModel.pages.count)")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            illustration

            VStack(alignment: .leading, spacing: 9) {
                Text(viewModel.currentPage.kicker)
                    .slimlyKicker(color: SlimlyColor.accent300)

                Text(viewModel.currentPage.title)
                    .font(.slimlyTitle)
                    .tracking(SlimlyTracking.title)

                Text(viewModel.currentPage.text)
                    .font(.slimlyBody)
                    .lineSpacing(4)
                    .foregroundStyle(SlimlyColor.neutral400)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    /// Картинка живёт в блоке постоянной высоты: иллюстрации разного размера
    /// иначе дёргали бы текст под собой на каждом шаге.
    private var illustration: some View {
        ZStack {
            illustrationBody
                .id(viewModel.pageIndex)
                .transition(.opacity.combined(with: .offset(y: 10)))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 262)
    }

    @ViewBuilder
    private var illustrationBody: some View {
        switch viewModel.currentPage.illustration {
        case .compress: CompressIllustration()
        case .convert: ConvertIllustration()
        case .audio: AudioIllustration()
        case .scan: ScanIllustration()
        }
    }

    private var actions: some View {
        VStack(spacing: 4) {
            Button(viewModel.nextTitle) {
                viewModel.next()
            }
            .buttonStyle(.slimlyPrimary)

            Button("Пропустить") {
                viewModel.skip()
            }
            .buttonStyle(.slimlyQuietLink)
            .frame(height: 42)
        }
        .padding(.horizontal, SlimlySpacing.screenHorizontal)
        .padding(.bottom, 6)
    }
}
