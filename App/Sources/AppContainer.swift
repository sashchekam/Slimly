import Foundation
import Observation
import AudioFeature
import AudioFeatureInterface
import CompressFeature
import CompressFeatureInterface
import ConvertFeature
import ConvertFeatureInterface
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
        let processing = processingService ?? MediaProcessor(library: mediaLibrary)
        self.mediaLibrary = mediaLibrary
        self.processingService = processing

        router = Router(root: HomeRoute.home)
        registry = RouteRegistry([
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
                processingService: processing
            ),
        ])
        deeplinks = DeeplinkRegistry(DeeplinkMap.mappers)
    }

    /// Диплинк — это одно присвоение состояния: маршруты раскладываются
    /// в корень и стек, SwiftUI сам дорисовывает иерархию.
    func handle(_ deeplink: DeeplinkURL) {
        guard let routes = deeplinks.routes(for: deeplink) else { return }
        router.replace(with: routes)
    }
}
