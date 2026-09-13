import SlimlyCore
import SlimlyNavigation

/// Публичный вход в пейволл.
///
/// Маршрут несёт только то, откуда его открыли: экран один, а спрос из разных
/// мест значит разное — в шаге выбора файлов упёрлись в предел, а в профиль
/// пришли посмотреть на себя. Способа показа маршрут не знает: пейволл
/// поднимают поверх всего, но решает это вызывающая сторона.
public enum PaywallRoute: Route {
    case paywall(PaywallSource)
}

/// Откуда пришли на пейволл. Значение уезжает в аналитику одной строкой.
public enum PaywallSource: String, Sendable {
    /// Плашка тарифа в профиле.
    case profile
    /// Предложение рядом со счётчиком выбранных файлов.
    case picker
    /// Сразу после вводного тура.
    case onboarding
    /// Ссылка `slimly://paywall`.
    case deeplink
}

public extension RemoteConfigKey where Value == Bool {
    /// Показывать ли пейволл сразу после тура. Ключ рядом с маршрутом:
    /// и то и другое — публичный договор пейволла, а решает по нему App.
    ///
    /// Умолчание — «показывать»: первый запуск и есть тот момент, когда
    /// про тариф слышат впервые. Выключатель нужен на случай, если это
    /// окажется дороже, чем даёт.
    static var paywallAfterTour: RemoteConfigKey { RemoteConfigKey("paywall_after_tour", default: true) }
}
