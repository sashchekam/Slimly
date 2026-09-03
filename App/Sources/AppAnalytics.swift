import SlimlyCore

/// Аналитика самого приложения: то, что случается вне экранов.
///
/// Первый пример модульной аналитики — дальше такая же пара «префикс плюс
/// словарь событий» заводится в каждой фиче и получает общую аналитику
/// параметром конструктора.
struct AppAnalytics: FeatureAnalytics {
    static let scope = "app"

    let analytics: any AnalyticsService

    /// Ссылка привела на экран. Адрес целиком не отправляем: в нём бывают
    /// параметры пользователя, а для отчёта хватает точки входа.
    func didOpenDeeplink(_ deeplink: DeeplinkURL) {
        track("deeplink_opened", ["target": .text(deeplink.host)])
    }

    /// Ссылка есть, а маршрута под неё нет: обычно это ярлык, оставшийся
    /// от прошлой версии, — такое видно только по аналитике.
    func didFailDeeplink(_ deeplink: DeeplinkURL) {
        track("deeplink_unknown", ["target": .text(deeplink.host)])
    }
}
