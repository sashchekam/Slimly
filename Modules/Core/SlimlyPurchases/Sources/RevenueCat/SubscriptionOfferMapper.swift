import Foundation
import RevenueCat
import SlimlyCore

/// Превращает пакет магазина в строку пейволла.
///
/// Отдельным воркером, потому что это единственное место, где типы SDK
/// встречаются с нашими: у сервиса покупок остаётся работа со SDK, а разбор
/// периодов и цен читается и проверяется сам по себе.
protocol SubscriptionOfferMapping: Sendable {
    func offer(for package: Package) -> SubscriptionOffer
}

struct SubscriptionOfferMapper: SubscriptionOfferMapping {
    func offer(for package: Package) -> SubscriptionOffer {
        let product = package.storeProduct

        return SubscriptionOffer(
            id: package.identifier,
            period: Self.period(of: package),
            price: product.localizedPriceString,
            pricePerMonth: Self.pricePerMonth(of: package),
            trialDays: Self.trialDays(of: product),
            monthlyAmount: product.pricePerMonth?.decimalValue
        )
    }

    /// Тип пакета, а не период продукта: в кабинете тариф кладут в ячейку
    /// («годовой», «месячный»), и витрина строится по ней. Своим сроком
    /// продукт отвечает только там, где ячейка нестандартная.
    private static func period(of package: Package) -> SlimlyCore.SubscriptionPeriod {
        switch package.packageType {
        case .annual: .year
        case .monthly: .month
        case .weekly: .week
        case .lifetime: .lifetime
        case .sixMonth, .threeMonth, .twoMonth, .custom, .unknown: period(of: package.storeProduct)
        }
    }

    private static func period(of product: StoreProduct) -> SlimlyCore.SubscriptionPeriod {
        guard let period = product.subscriptionPeriod else { return .lifetime }

        switch (period.unit, period.value) {
        case (.year, 1): return .year
        case (.month, 1): return .month
        case (.week, 1): return .week
        default: return .other
        }
    }

    /// Пересчёт на месяц показываем только там, где он что-то объясняет:
    /// у недельного тарифа он вводил бы в заблуждение, у разового платежа
    /// его нет вовсе.
    private static func pricePerMonth(of package: Package) -> String? {
        guard (Self.period(of: package).months ?? 0) > 1 else { return nil }

        return package.storeProduct.localizedPricePerMonth
    }

    /// Бесплатный период — это скидка с нулевой ценой. Скидка со сниженной
    /// ценой (первый месяц дешевле) пробным периодом не считается: за неё
    /// платят сразу, и обещать «бесплатно» нельзя.
    private static func trialDays(of product: StoreProduct) -> Int? {
        guard
            let discount = product.introductoryDiscount,
            discount.paymentMode == .freeTrial
        else { return nil }

        return days(in: discount.subscriptionPeriod)
    }

    private static func days(in period: RevenueCat.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: period.value
        case .week: period.value * 7
        case .month: period.value * 30
        case .year: period.value * 365
        }
    }
}
