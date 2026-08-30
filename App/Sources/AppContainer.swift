import Foundation
import Observation
import AudioFeature
import AudioFeatureInterface
import CompressFeature
import CompressFeatureInterface
import ConvertFeature
import ConvertFeatureInterface
import DebugFeature
import DebugFeatureInterface
import HomeFeature
import HomeFeatureInterface
import ProfileFeature
import ProfileFeatureInterface
import ScanFeature
import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaKit
import SlimlyNavigation

/// Единственное место, которое знает про все фичи сразу: здесь живут сервисы,
/// реестр «маршрут → экран», состав главного экрана и таблица диплинков.
/// Фичи про контейнер не знают — зависимости приходят к ним явными
/// параметрами в `*Feature.resolver(...)`.
@MainActor
@Observable
final class AppContainer {
    // MARK: Сервисы

    let mediaLibrary: any MediaLibrary
    let processingService: any MediaProcessingService
    let debugSettings = DebugSettings()

    // MARK: Навигация

    let router: Router
    let registry: RouteRegistry

    private let deeplinks: DeeplinkRegistry

    /// Обработчику нужна та же медиатека, из которой выбирали файлы:
    /// он забирает у неё оригиналы и возвращает результат. Поэтому сервис
    /// собирается после библиотеки, а не значением по умолчанию.
    init(
        mediaLibrary: any MediaLibrary = PhotosMediaLibrary(),
        processingService: (any MediaProcessingService)? = nil
    ) {
        // Хранилище статистики создаётся здесь, а не внутри обработчика:
        // отладочное меню сбрасывает те же цифры, что показывает профиль,
        // и экземпляр у них должен быть один.
        let statsStore = ProcessingStatsStore()
        let processing = processingService
            ?? MediaProcessor(library: mediaLibrary, statsStore: statsStore)
        self.mediaLibrary = mediaLibrary
        self.processingService = processing

        router = Router(root: HomeRoute.home)

        var resolvers: [RouteResolver] = [
            HomeFeature.resolver(tools: HomeTools.all, profile: ProfileRoute.profile),
            CompressFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing
            ),
            ConvertFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing
            ),
            AudioFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing
            ),
            ScanFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing
            ),
            ProfileFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                debugMenu: Self.debugMenuRoute
            ),
        ]

        // В релизной сборке резолвера нет: маршрут остаётся значением,
        // которому не соответствует ни один экран, и меню недостижимо.
        #if DEBUG
        resolvers.append(
            DebugFeature.resolver(settings: debugSettings, statsStore: statsStore)
        )
        #endif

        registry = RouteRegistry(resolvers)
        deeplinks = DeeplinkRegistry(DeeplinkMap.mappers)
    }

    /// Куда ведёт пятое нажатие на строку версии. В релизе — никуда.
    private static var debugMenuRoute: (any Route)? {
        #if DEBUG
        DebugRoute.menu
        #else
        nil
        #endif
    }

    /// Диплинк — это одно присвоение состояния: маршруты раскладываются
    /// в корень и стек, SwiftUI сам дорисовывает иерархию.
    func handle(_ deeplink: DeeplinkURL) {
        guard let routes = deeplinks.routes(for: deeplink) else { return }
        router.replace(with: routes)
    }

    #if DEBUG
    /// Меню приезжает поверх всего: тряхнуть могли на любом шаге флоу, и
    /// уводить пользователя с его места незачем — «Готово» вернёт как было.
    func openDebugMenu() {
        guard router.fullScreenCover == nil else { return }
        router.sheet = nil
        router.cover(DebugRoute.menu)
    }
    #endif
}
