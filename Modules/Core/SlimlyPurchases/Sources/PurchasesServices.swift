import Foundation
import SlimlyCore

/// Сервисы, собранные поверх RevenueCat, — единственное, что модуль отдаёт
/// наружу. Сами типы SDK за границу не выходят: приложение получает
/// `any PurchaseService` и тариф за протоколом и про RevenueCat не знает.
///
/// Без `RevenueCat-Info.plist` состав подменяется: в отладочной сборке —
/// витриной-образцом, чтобы пейволл было чем открыть, в релизной — пустым
/// магазином. Сборка без ключей — это рабочая сборка без подписки,
/// а не упавшая.
@MainActor
public struct PurchasesServices {
    public let purchases: any PurchaseService
    /// Тариф пользователя. Живёт здесь, потому что меняет его ответ магазина,
    /// а читают его экраны — экземпляр у них должен быть один.
    public let pro: StoredProSubscription

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.init(bootstrap: PurchasesBootstrap(), pro: StoredProSubscription(storage: storage))
    }

    /// Готовый состав — превью и тестам.
    public init(purchases: any PurchaseService, pro: StoredProSubscription) {
        self.purchases = purchases
        self.pro = pro
    }

    init(bootstrap: any PurchasesBootstrapping, pro: StoredProSubscription) {
        self.pro = pro

        guard bootstrap.start() else {
            #if DEBUG
            purchases = SamplePurchases(pro: pro)
            #else
            purchases = NoPurchases()
            // Магазина нет — значит, и права на Pro неоткуда взяться: иначе
            // тариф остался бы включённым с прошлой сборки навсегда.
            pro.update(isActive: false)
            #endif
            return
        }

        let service = RevenueCatPurchases(pro: pro)
        // Слушать магазин начинаем сразу, а не при открытии пейволла: отмена
        // подписки и покупка на другом устройстве приходят сами, и Pro должно
        // гаснуть без нашего запроса.
        service.watchCustomer()
        purchases = service
    }
}
