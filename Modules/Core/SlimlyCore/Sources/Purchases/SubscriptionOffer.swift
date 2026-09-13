import Foundation

/// Тариф, который пейволл показывает строкой: что покупаем и по какой цене.
///
/// Цена приезжает готовой строкой, а не числом: её форматирует магазин —
/// он один знает и валюту аккаунта, и то, как её пишут на языке витрины.
/// Пересчитывать цену самим значило бы разойтись с тем, что человек увидит
/// в системном окне оплаты.
public struct SubscriptionOffer: Identifiable, Hashable, Sendable {
    /// Идентификатор пакета в магазине: по нему покупка находит, что продавать.
    public let id: String
    public let period: SubscriptionPeriod
    /// Цена за период целиком — «2 990 ₽».
    public let price: String
    /// Она же в пересчёте на месяц. `nil` — у периода короче месяца
    /// и у разового платежа: пересчитывать там нечего.
    public let pricePerMonth: String?
    /// Сколько дней бесплатно до первого списания. `nil` — пробного периода нет.
    public let trialDays: Int?
    /// Та же месячная цена числом — только чтобы сравнить тарифы между собой
    /// и сказать «выгоднее на столько-то». Показывать её нельзя: валюту
    /// и её запись знает магазин, а не мы.
    public let monthlyAmount: Decimal?

    public init(
        id: String,
        period: SubscriptionPeriod,
        price: String,
        pricePerMonth: String? = nil,
        trialDays: Int? = nil,
        monthlyAmount: Decimal? = nil
    ) {
        self.id = id
        self.period = period
        self.price = price
        self.pricePerMonth = pricePerMonth
        self.trialDays = trialDays
        self.monthlyAmount = monthlyAmount
    }

    public var hasTrial: Bool { (trialDays ?? 0) > 0 }
}

/// За какой срок платят. Названия периодов переводит тот, кто их показывает:
/// здесь важен только сам срок.
public enum SubscriptionPeriod: String, Hashable, Sendable, CaseIterable {
    case week
    case month
    case year
    /// Разовый платёж навсегда.
    case lifetime
    /// Срок, которого нет в этом списке, — полугодие и прочая экзотика.
    case other

    /// Сколько месяцев в периоде. Нужен для «выгоднее на столько-то»:
    /// сравнивать годовой тариф с месячным можно только приведя их к общему.
    public var months: Int? {
        switch self {
        case .week: nil
        case .month: 1
        case .year: 12
        case .lifetime, .other: nil
        }
    }
}
