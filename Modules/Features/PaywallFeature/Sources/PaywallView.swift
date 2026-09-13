import SlimlyDesignSystem
import SwiftUI

/// Пейволл: что даёт тариф, сколько он стоит и одна кнопка.
///
/// Экран поднимают поверх всего, а не пушат: разговор про деньги прерывает
/// то, чем человек занят, и закончиться должен возвратом ровно туда же.
public struct PaywallView: View {
    @State
    private var viewModel: PaywallViewModel

    public init(viewModel: PaywallViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .slimlyScreen()
        .slimlyToast(viewModel.toast)
        .task { await viewModel.load() }
    }

    /// В шапке только выход. Заголовок живёт в самом предложении: он крупный
    /// и уезжает со скроллом, потому что читается один раз.
    private var header: some View {
        HStack {
            Spacer(minLength: 0)

            Button {
                viewModel.close()
            } label: {
                SlimlyIcon(.close, width: 12)
                    .foregroundStyle(SlimlyColor.neutral300)
                    .frame(width: 30, height: 30)
                    .background(SlimlyColor.text.opacity(0.09), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Paywall.close))
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isPro {
            active
        } else if viewModel.isLoading {
            loading
        } else if viewModel.isEmpty {
            unavailable
        } else {
            offer
        }
    }

    // MARK: Предложение

    private var offer: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pitch
                    benefits
                    plans
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 8)
            }

            SlimlyBottomAction {
                actions
            }
        }
    }

    private var pitch: some View {
        VStack(alignment: .leading, spacing: 12) {
            SlimlyProMark(isActive: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Paywall.title)
                    .font(.slimlyTitle)
                    .tracking(SlimlyTracking.title)

                Text(L10n.Paywall.subtitle)
                    .font(.slimlyBody)
                    .lineSpacing(4)
                    .foregroundStyle(SlimlyColor.neutral400)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(viewModel.benefits, id: \.self) { benefit in
                BenefitRow(text: benefit)
            }
        }
    }

    private var plans: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.plans) { plan in
                PlanCard(plan: plan) { viewModel.select(plan.id) }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.buy() }
            } label: {
                // Пока идёт покупка, подпись уступает место кольцу: система
                // своё окно рисует не мгновенно, и без этого кажется, что
                // нажатие не сработало.
                if viewModel.isPurchasing {
                    SlimlySpinner(size: 18)
                } else {
                    Text(viewModel.ctaTitle)
                }
            }
            .buttonStyle(.slimlyPrimary)
            .disabled(viewModel.isPurchasing)

            if let note = viewModel.ctaNote {
                Text(note)
                    .font(.slimlyCaption)
                    .foregroundStyle(SlimlyColor.neutral400)
                    .multilineTextAlignment(.center)
            }

            Button(L10n.Paywall.restore) {
                Task { await viewModel.restore() }
            }
            .buttonStyle(.slimlyQuietLink)
            .disabled(viewModel.isPurchasing)
            .frame(height: 34)

            Text(L10n.Paywall.legal)
                .font(.slimlyNano)
                .foregroundStyle(SlimlyColor.neutral600)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Остальные состояния

    private var loading: some View {
        SlimlySpinner()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Витрины нет — значит, и предлагать нечего: вместо пустого списка
    /// объяснение и одна кнопка. Тариф в этот момент не расхваливают:
    /// купить его всё равно нельзя.
    private var unavailable: some View {
        VStack(spacing: 16) {
            Text(L10n.Paywall.unavailable)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral400)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(L10n.Paywall.retry) {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.slimlyCompact)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Тариф уже подключён: так экран выглядит и сразу после удачной покупки,
    /// и когда на пейволл пришли по ссылке с активной подпиской. Предложение
    /// в обоих случаях лишнее — остаётся подтверждение.
    private var active: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                SlimlyProMark(isActive: true)

                Text(L10n.Paywall.activeTitle)
                    .font(.slimlyTitle)
                    .tracking(SlimlyTracking.title)
                    .multilineTextAlignment(.center)

                Text(L10n.Paywall.activeNote)
                    .font(.slimlyBody)
                    .lineSpacing(4)
                    .foregroundStyle(SlimlyColor.neutral400)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SlimlyBottomAction {
                Button(L10n.Paywall.done) {
                    viewModel.close()
                }
                .buttonStyle(.slimlyPrimary)
            }
        }
    }
}
