import PaywallFeatureInterface
import SlimlyCore

/// Аналитика пейволла.
///
/// Здесь у приложения единственный разговор про деньги, поэтому события
/// описывают воронку целиком: открыли — выбрали тариф — начали покупку —
/// чем кончилось. Источник едет с каждым событием: сравнивать имеет смысл
/// не пейволл вообще, а вход в него.
public struct PaywallAnalytics: FeatureAnalytics {
    public static let scope = "paywall"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Экран открыт. `offers` — сколько тарифов на нём показали: ноль значит,
    /// что человек увидел пустую витрину, и это отказ не его, а наш.
    func didOpen(from source: PaywallSource, offers: Int) {
        track("opened", ["source": .text(source.rawValue), "offers": .int(offers)])
    }

    /// Выбрали другой тариф. Первый выбор ставим мы сами и не считаем:
    /// событие означает, что предложенный по умолчанию не подошёл.
    func didPickPlan(_ period: SubscriptionPeriod) {
        track("plan_picked", ["plan": .text(period.rawValue)])
    }

    /// Нажали кнопку покупки — дальше говорит система.
    func didStartPurchase(_ period: SubscriptionPeriod, trial: Bool) {
        track("purchase_started", ["plan": .text(period.rawValue), "trial": .flag(trial)])
    }

    /// Покупка прошла. Ради этого события существует весь экран.
    func didPurchase(_ period: SubscriptionPeriod, trial: Bool, from source: PaywallSource) {
        track(
            "purchase_finished",
            [
                "plan": .text(period.rawValue),
                "trial": .flag(trial),
                "source": .text(source.rawValue),
            ]
        )
    }

    /// Системное окно оплаты закрыли, не заплатив. Отказ на этом шаге —
    /// не сбой, но по нему видно, где цена перестаёт устраивать.
    func didCancelPurchase(_ period: SubscriptionPeriod) {
        track("purchase_cancelled", ["plan": .text(period.rawValue)])
    }

    /// Покупка сорвалась отказом магазина. Текст ошибки не отправляем —
    /// в нём бывает и имя аккаунта, и адрес почты.
    func didFailPurchase(_ period: SubscriptionPeriod) {
        track("purchase_failed", ["plan": .text(period.rawValue)])
    }

    /// Нажали «восстановить». `restored` — вернулось ли что-нибудь: пустой
    /// ответ означает, что человек ищет покупку, которой у него нет.
    func didRestore(_ restored: Bool) {
        track("restored", ["restored": .flag(restored)])
    }

    /// Ушли с пейволла, ничего не купив.
    func didClose(from source: PaywallSource) {
        track("closed", ["source": .text(source.rawValue)])
    }
}
