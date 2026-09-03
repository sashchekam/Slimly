import Foundation

/// База для аналитики модуля.
///
/// Модуль не отправляет события сам: он получает общую аналитику приложения
/// параметром конструктора и складывает поверх неё свой словарь событий —
/// со своими именами, своими параметрами и своим префиксом. Тогда все имена
/// модуля видны в одном файле, а место вызова пишет `analytics.didPickFiles(3)`
/// вместо строкового литерала.
///
/// ```swift
/// struct CompressAnalytics: FeatureAnalytics {
///     static let scope = "compress"
///     let analytics: any AnalyticsService
///
///     func didPickFiles(_ count: Int) {
///         track("files_picked", ["count": .int(count)])
///     }
/// }
/// ```
public protocol FeatureAnalytics: Sendable {
    /// Префикс имён событий модуля — «compress», «scan», «onboarding».
    /// По нему события модуля отбираются в отчёте одной маской.
    static var scope: String { get }

    var analytics: any AnalyticsService { get }
}

public extension FeatureAnalytics {
    func track(_ name: String, _ parameters: [String: AnalyticsValue] = [:]) {
        analytics.track(AnalyticsEvent("\(Self.scope)_\(name)", parameters))
    }
}
