import Foundation
import Observation
import HomeFeature
import HomeFeatureInterface
import SlimlyCore
import SlimlyNavigation
import WelcomeFeature
import WelcomeFeatureInterface

/// Composition root приложения (архитектура B, см. ARCHITECTURE.md).
///
/// Единственное место, которое знает про все фичи сразу: здесь живут сервисы,
/// реестр «маршрут → экран» и таблица диплинков. Фичи про контейнер не знают —
/// зависимости приходят к ним явными параметрами в `*Feature.resolver(...)`.
@MainActor
@Observable
final class AppContainer {
    // MARK: Сервисы

    let authService: any AuthService

    // MARK: Навигация

    let rootRouter: Router
    let registry: RouteRegistry

    private let deeplinks: DeeplinkRegistry

    init(authService: any AuthService = StubAuthService()) {
        self.authService = authService
        rootRouter = Router(root: WelcomeRoute.signIn)
        registry = RouteRegistry([
            WelcomeFeature.resolver(authService: authService),
            HomeFeature.resolver(authService: authService),
        ])
        deeplinks = DeeplinkRegistry(DeeplinkMap.mappers)
    }

    /// Диплинк — это одно присвоение состояния: маршруты раскладываются
    /// в корень + стек, SwiftUI сам дорисовывает нужную иерархию.
    func handle(_ deeplink: DeeplinkURL) {
        guard let routes = deeplinks.routes(for: deeplink) else { return }
        rootRouter.replace(with: routes)
    }
}
