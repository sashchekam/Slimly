import Foundation
import Observation
import PaywallFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class PaywallViewModel {
    /// Строка тарифа в списке выбора.
    ///
    /// Готовые строки, а не предложение магазина: вью не должна знать
    /// ни про валюту, ни про то, как считается выгода.
    public struct Plan: Identifiable, Sendable {
        public let id: String
        /// Название срока — «Год», «Месяц».
        public let title: String
        public let price: String
        /// Цена в пересчёте на месяц. `nil` — у коротких сроков: там пересчёт
        /// ничего не объясняет.
        public let note: String?
        /// Насколько тариф выгоднее самого дорогого из списка. `nil` — если
        /// сравнивать не с чем или разница в пределах пары процентов.
        public let badge: String?
        public let isSelected: Bool
    }

    public private(set) var isLoading = true
    /// Идёт покупка или восстановление: пока система показывает своё окно,
    /// экран не должен принимать второе нажатие.
    public private(set) var isPurchasing = false
    public private(set) var toast: String?

    /// Тариф спрашивают на каждой перерисовке, а не запоминают при загрузке:
    /// покупка меняет его прямо на этом экране, и экран по нему же
    /// и переключается на подтверждение.
    public var isPro: Bool { pro.isActive }

    private var offers: [SubscriptionOffer] = []
    private var selectedID: String?

    private let source: PaywallSource
    private let purchases: any PurchaseService
    private let pro: any ProSubscription
    private let analytics: PaywallAnalytics
    private let router: Router

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    public init(
        source: PaywallSource,
        purchases: any PurchaseService,
        pro: any ProSubscription = NoProSubscription(),
        analytics: PaywallAnalytics,
        router: Router
    ) {
        self.source = source
        self.purchases = purchases
        self.pro = pro
        self.analytics = analytics
        self.router = router
    }

    // MARK: Витрина

    /// Витрина пуста: магазина нет или в кабинете не выложено ни одного
    /// тарифа. Экран об этом говорит прямо — молчаливый пустой список
    /// читался бы как поломка.
    public var isEmpty: Bool { !isLoading && offers.isEmpty }

    public var plans: [Plan] { offers.map(plan(for:)) }

    /// Что даёт тариф. Список собирается на каждом обращении: строки
    /// переведены, а язык меняют на ходу.
    public var benefits: [String] {
        [L10n.Benefit.batch, L10n.Benefit.quality, L10n.Benefit.pages, L10n.Benefit.next]
    }

    public func load() async {
        await fetch()
        analytics.didOpen(from: source, offers: offers.count)
    }

    public func retry() async {
        await fetch()
    }

    private func fetch() async {
        isLoading = true
        offers = (try? await purchases.offers()) ?? []
        // Выбранным сразу стоит самый выгодный: пейволл без выбранного тарифа
        // просит сделать лишний шаг до того, как согласился на главный.
        selectedID = best?.id
        isLoading = false
    }

    /// Самый выгодный — тот, у кого месяц дешевле всех. Если сравнивать
    /// нечем (разовый платёж, единственный тариф), берём первый.
    private var best: SubscriptionOffer? {
        let cheapest = offers
            .filter { $0.monthlyAmount != nil }
            .min { ($0.monthlyAmount ?? 0) < ($1.monthlyAmount ?? 0) }
        return cheapest ?? offers.first
    }

    private var selected: SubscriptionOffer? {
        offers.first { $0.id == selectedID } ?? offers.first
    }

    public func select(_ id: String) {
        guard id != selectedID, let offer = offers.first(where: { $0.id == id }) else { return }

        selectedID = id
        analytics.didPickPlan(offer.period)
    }

    // MARK: Кнопка

    /// Пробный период меняет смысл кнопки: соглашаются не на списание,
    /// а на то, чтобы попробовать.
    public var ctaTitle: String {
        selected?.hasTrial == true ? L10n.Paywall.tryFree : L10n.Paywall.subscribe
    }

    /// Строка под кнопкой: что именно произойдёт по нажатию. Обещание
    /// «бесплатно» без срока и без «потом» — это обман, поэтому строки две.
    public var ctaNote: String? {
        guard let offer = selected else { return nil }
        guard let days = offer.trialDays, days > 0 else { return L10n.Paywall.renewNote }

        return L10n.Paywall.trialNote(L10n.Count.day(days))
    }

    public func buy() async {
        guard let offer = selected, !isPurchasing else { return }

        isPurchasing = true
        analytics.didStartPurchase(offer.period, trial: offer.hasTrial)

        do {
            switch try await purchases.purchase(offer) {
            case .purchased:
                analytics.didPurchase(offer.period, trial: offer.hasTrial, from: source)
            case .cancelled:
                analytics.didCancelPurchase(offer.period)
            }
        } catch {
            analytics.didFailPurchase(offer.period)
            say(L10n.Paywall.failed)
        }

        isPurchasing = false
    }

    /// Восстановление обязательно по правилам App Store, но нужно оно редко:
    /// поэтому это ссылка внизу, а не второе главное действие.
    public func restore() async {
        guard !isPurchasing else { return }

        isPurchasing = true
        let restored = (try? await purchases.restore()) ?? false
        analytics.didRestore(restored)
        isPurchasing = false

        say(restored ? L10n.Paywall.restored : L10n.Paywall.nothingToRestore)
    }

    // MARK: Выход

    /// Уход без покупки — тоже ответ, и его считают отдельно от закрытия
    /// экрана после удачной покупки.
    public func close() {
        if !isPro {
            analytics.didClose(from: source)
        }
        router.dismiss()
    }

    // MARK: Сборка строк

    private func plan(for offer: SubscriptionOffer) -> Plan {
        Plan(
            id: offer.id,
            title: Self.title(of: offer.period),
            price: offer.price,
            note: offer.pricePerMonth.map { L10n.Paywall.perMonth($0) },
            badge: savings(for: offer).map { L10n.Paywall.save($0.formatted(.percent.locale(L10nBundle.locale))) },
            isSelected: offer.id == selected?.id
        )
    }

    private static func title(of period: SubscriptionPeriod) -> String {
        switch period {
        case .week: L10n.Plan.week
        case .month: L10n.Plan.month
        case .year: L10n.Plan.year
        case .lifetime: L10n.Plan.lifetime
        case .other: L10n.Plan.other
        }
    }

    /// Выгода считается от самого дорогого месяца в списке, а не от следующего
    /// по цене: человек сравнивает годовой тариф с недельным, и цифра должна
    /// отвечать на тот же вопрос.
    private func savings(for offer: SubscriptionOffer) -> Int? {
        guard
            let amount = offer.monthlyAmount,
            let peak = offers.compactMap(\.monthlyAmount).max(),
            peak > 0,
            amount < peak
        else { return nil }

        let share = ((peak - amount) as NSDecimalNumber).doubleValue / (peak as NSDecimalNumber).doubleValue
        let percent = Int((share * 100).rounded())
        // Мелкая разница выглядит уловкой: «выгода 3%» подрывает доверие
        // к соседней строке, где выгода настоящая.
        return percent >= 10 ? percent : nil
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
