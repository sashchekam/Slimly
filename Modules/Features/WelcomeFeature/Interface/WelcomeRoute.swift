import SlimlyNavigation

/// Публичный вход в фичу приветствия.
///
/// Модуль тонкий и без UI: его импортирует кто угодно, чтобы открыть экран,
/// не зная ни про `WelcomeView`, ни про `WelcomeViewModel`.
public enum WelcomeRoute: Route {
    case signIn
}
