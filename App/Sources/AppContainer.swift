import Foundation
import Observation
import CompressFeature
import CompressFeatureInterface
import ProfileFeature
import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

/// Composition root приложения (архитектура B, см. ARCHITECTURE.md).
///
/// Единственное место, которое знает про все фичи сразу: здесь живут сервисы,
/// реестр «маршрут → экран», состав табов и таблица диплинков. Фичи про
/// контейнер не знают — зависимости приходят к ним явными параметрами
/// в `*Feature.resolver(...)`.
@MainActor
@Observable
final class AppContainer {
    // MARK: Сервисы

    let mediaLibrary: any MediaLibrary
    let compressionService: any CompressionService

    // MARK: Навигация

    let tabRouter: TabRouter
    let registry: RouteRegistry

    private let deeplinks: DeeplinkRegistry

    init(
        mediaLibrary: any MediaLibrary = StubMediaLibrary(),
        compressionService: any CompressionService = StubCompressionService()
    ) {
        self.mediaLibrary = mediaLibrary
        self.compressionService = compressionService

        let tabRouter = TabRouter(items: SqueezeTab.routerItems)
        self.tabRouter = tabRouter

        registry = RouteRegistry([
            CompressFeature.resolver(
                mediaLibrary: mediaLibrary,
                compressionService: compressionService,
                // Экран результата зовёт «смотреть в профиле» — переключение
                // таба знает только App, поэтому оно приезжает замыканием.
                showProfile: { tabRouter.selection = SqueezeTab.profile.id }
            ),
            ProfileFeature.resolver(
                mediaLibrary: mediaLibrary,
                compressionService: compressionService
            ),
        ])
        deeplinks = DeeplinkRegistry(DeeplinkMap.mappers)
    }

    /// Диплинк — это одно присвоение состояния: нужный таб выбирается,
    /// его маршруты раскладываются в корень + стек, SwiftUI сам дорисовывает
    /// иерархию.
    func handle(_ deeplink: DeeplinkURL) {
        guard
            let routes = deeplinks.routes(for: deeplink),
            let first = routes.first,
            let tab = SqueezeTab.owner(of: first)
        else { return }

        tabRouter.selection = tab.id
        tabRouter.router(for: tab.id).replace(with: routes)
    }
}
