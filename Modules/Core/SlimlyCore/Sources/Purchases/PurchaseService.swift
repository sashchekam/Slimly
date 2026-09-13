import Foundation

/// Покупки в приложении — единственная дверь наружу.
///
/// Кто именно за ней стоит (RevenueCat, образец без магазина, заглушка
/// в превью), знает только сборка приложения. Пейволл держит
/// `any PurchaseService` и не тянет за собой ни одного SDK.
///
/// Живёт на главной очереди: покупку начинает нажатие на экране, а её итог
/// тут же меняет состояние тарифа, за которым наблюдают вью.
@MainActor
public protocol PurchaseService: Sendable {
    /// Что сейчас продаётся. Пустой список — продавать нечего: ни магазина,
    /// ни витрины в кабинете.
    func offers() async throws -> [SubscriptionOffer]

    func purchase(_ offer: SubscriptionOffer) async throws -> PurchaseResult

    /// Вернуть покупки, сделанные раньше. `true` — тариф снова активен.
    func restore() async throws -> Bool
}

/// Чем закончилось системное окно оплаты.
///
/// Отказ — это не ошибка: человек закрыл окно, и сказать ему об этом нечего.
/// Поэтому он приходит значением, а не броском.
public enum PurchaseResult: Sendable {
    case purchased
    case cancelled
}

/// Отказ магазина, о котором есть что сказать человеку.
///
/// Ошибки сети и оплаты приходят от системы своими типами — их пейволл
/// показывает одной строкой «не получилось». Здесь только то, чего в них нет.
public enum PurchaseFailure: Error, Sendable {
    /// Тариф исчез с витрины, пока экран был открыт: пакет с таким
    /// идентификатором магазин больше не отдаёт.
    case unavailable
}

/// Магазина нет: витрина пустая, купить нечего, возвращать нечего.
///
/// Нужна не только превью: без ключа RevenueCat приложение всё равно должно
/// запускаться и работать — просто без подписки.
public struct NoPurchases: PurchaseService {
    public init() { }

    public func offers() async throws -> [SubscriptionOffer] { [] }

    public func purchase(_ offer: SubscriptionOffer) async throws -> PurchaseResult { .cancelled }

    public func restore() async throws -> Bool { false }
}
