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
    /// параметры пользователя, а для отчёта хватает точки входа и того,
    /// откуда по ней пришли.
    func didOpenDeeplink(_ deeplink: DeeplinkURL, from source: DeeplinkSource) {
        track(
            "deeplink_opened",
            [
                "target": .text(deeplink.host),
                "source": .text(source.rawValue),
            ]
        )
    }

    /// Ссылка есть, а маршрута под неё нет: обычно это ярлык, оставшийся
    /// от прошлой версии, — такое видно только по аналитике.
    func didFailDeeplink(_ deeplink: DeeplinkURL) {
        track("deeplink_unknown", ["target": .text(deeplink.host)])
    }
}

/// Откуда пришла ссылка.
///
/// Виджет, ссылка из заметки и переход из браузера приходят одинаково —
/// системным открытием адреса, и разделить их всё равно нечем. А вот меню
/// иконки кладёт действие в свой ящик, и по этой границе видно, пользуются
/// ли быстрыми действиями вообще.
enum DeeplinkSource: String {
    case url
    case shortcut
}
