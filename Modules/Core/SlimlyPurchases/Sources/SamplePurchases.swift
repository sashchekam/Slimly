import Foundation
import SlimlyCore

/// Витрина-образец: три тарифа с придуманными ценами и покупка, которая
/// всегда проходит.
///
/// Нужна ровно для одного — увидеть пейволл до того, как заведён кабинет
/// RevenueCat и продукты в App Store Connect. Поэтому она есть только
/// в отладочной сборке: в релизе без магазина продавать нечего, и об этом
/// честно говорит `NoPurchases`.
@MainActor
final class SamplePurchases: PurchaseService {
    private let pro: StoredProSubscription
    /// Задержка перед ответом. Настоящий магазин отвечает не мгновенно,
    /// и без паузы состояние загрузки на экране никогда не увидеть.
    private let delay: Duration

    init(pro: StoredProSubscription, delay: Duration = .milliseconds(600)) {
        self.pro = pro
        self.delay = delay
    }

    func offers() async throws -> [SubscriptionOffer] {
        try? await Task.sleep(for: delay)

        return [
            SubscriptionOffer(
                id: "sample.year",
                period: .year,
                price: "2 990 ₽",
                pricePerMonth: "249 ₽",
                trialDays: 7,
                monthlyAmount: 249
            ),
            SubscriptionOffer(id: "sample.month", period: .month, price: "399 ₽", monthlyAmount: 399),
            SubscriptionOffer(id: "sample.week", period: .week, price: "149 ₽", monthlyAmount: 596),
        ]
    }

    func purchase(_ offer: SubscriptionOffer) async throws -> PurchaseResult {
        try? await Task.sleep(for: delay)
        pro.update(isActive: true)
        return .purchased
    }

    func restore() async throws -> Bool {
        try? await Task.sleep(for: delay)
        return pro.isActive
    }
}
