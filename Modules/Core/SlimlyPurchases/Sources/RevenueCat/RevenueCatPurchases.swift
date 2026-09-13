import Foundation
import OSLog
import RevenueCat
import SlimlyCore

/// Покупки поверх RevenueCat — единственное место в приложении, где живут
/// типы SDK.
///
/// Наружу уезжают наши модели, а сами пакеты остаются здесь: покупать надо
/// ровно тот объект, что дал магазин, поэтому предложение и пакет связаны
/// идентификатором, а не пересобираются заново.
@MainActor
final class RevenueCatPurchases: PurchaseService {
    private static let logger = Logger(subsystem: "com.slimly", category: "purchases")

    /// Право, по которому включается Pro. Имя задано в кабинете RevenueCat
    /// и одинаково для всех тарифов: экраны спрашивают «есть ли Pro»,
    /// а не «какой из продуктов куплен».
    private let entitlement: String
    private let mapper: any SubscriptionOfferMapping
    /// Тариф, который меняет ответ магазина. Тот же экземпляр читают экраны.
    private let pro: StoredProSubscription

    private var packages: [String: Package] = [:]

    private var watchTask: Task<Void, Never>?

    init(
        entitlement: String = "pro",
        mapper: any SubscriptionOfferMapping = SubscriptionOfferMapper(),
        pro: StoredProSubscription
    ) {
        self.entitlement = entitlement
        self.mapper = mapper
        self.pro = pro
    }

    deinit {
        watchTask?.cancel()
    }

    func offers() async throws -> [SubscriptionOffer] {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else {
            Self.logger.warning("витрина пуста — в кабинете нет текущего offering")
            return []
        }

        packages = Dictionary(
            current.availablePackages.map { ($0.identifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return current.availablePackages.map(mapper.offer(for:))
    }

    func purchase(_ offer: SubscriptionOffer) async throws -> PurchaseResult {
        guard let package = packages[offer.id] else { throw PurchaseFailure.unavailable }

        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else { return .cancelled }

        apply(result.customerInfo)
        return .purchased
    }

    func restore() async throws -> Bool {
        apply(try await Purchases.shared.restorePurchases())
        return pro.isActive
    }

    /// Слушать магазин, пока приложение живо: подписку могли оформить
    /// на другом устройстве, вернуть из настроек или отменить — тогда Pro
    /// гаснет само, без нашего запроса.
    func watchCustomer() {
        guard watchTask == nil else { return }

        watchTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { return }
                self?.apply(info)
            }
        }
    }

    private func apply(_ info: CustomerInfo) {
        pro.update(isActive: info.entitlements[entitlement]?.isActive == true)
    }
}
