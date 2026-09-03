import Foundation

/// Общая аналитика приложения — единственная дверь наружу.
///
/// Кто именно за ней стоит (Firebase, консоль, заглушка в тесте), знает
/// только сборка приложения. Модуль держит `any AnalyticsService` и не тянет
/// за собой ни одного SDK.
public protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)

    /// Свойство живёт до переустановки и приезжает со всеми следующими
    /// событиями. `nil` — снять.
    func set(_ property: AnalyticsUserProperty, to value: String?)
}

/// Аналитика, которая никуда не отправляет.
///
/// Нужна не только тестам: без `GoogleService-Info.plist` приложение всё
/// равно должно запускаться и работать, поэтому событиям нужен приёмник,
/// который молчит.
public struct NoAnalytics: AnalyticsService {
    public init() { }

    public func track(_ event: AnalyticsEvent) { }

    public func set(_ property: AnalyticsUserProperty, to value: String?) { }
}
