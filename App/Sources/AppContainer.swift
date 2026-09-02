import AudioFeature
import AudioFeatureInterface
import CompressFeature
import CompressFeatureInterface
import ConvertFeature
import ConvertFeatureInterface
import DebugFeature
import DebugFeatureInterface
import Foundation
import HomeFeature
import HomeFeatureInterface
import Observation
import OnboardingFeature
import OnboardingFeatureInterface
import ProfileFeature
import ProfileFeatureInterface
import ScanFeature
import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyMediaKit
import SlimlyNavigation
import SwiftUI

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
    /// Кадр из готового файла для экрана просмотра. Отдельно от медиатеки:
    /// результат обработки — файл на диске, а не ассет.
    let previewRenderer: any MediaPreviewRenderer
    let debugSettings = DebugSettings()
    /// Отметка о показанном туре. Живёт здесь, а не в фиче: с неё начинается
    /// выбор корня, и тот же экземпляр потом ставит отметку.
    let onboardingState: any OnboardingState

    // MARK: Навигация

    let router: Router
    let registry: RouteRegistry

    private let deeplinks: DeeplinkRegistry

    /// Обработчику нужна та же медиатека, из которой выбирали файлы:
    /// он забирает у неё оригиналы и возвращает результат. Поэтому сервис
    /// собирается после библиотеки, а не значением по умолчанию.
    init(
        mediaLibrary: any MediaLibrary = PhotosMediaLibrary(),
        processingService: (any MediaProcessingService)? = nil,
        previewRenderer: any MediaPreviewRenderer = SystemMediaPreviewRenderer(),
        onboardingState: any OnboardingState = DefaultsOnboardingState()
    ) {
        // Хранилище статистики создаётся здесь, а не внутри обработчика:
        // отладочное меню сбрасывает те же цифры, что показывает профиль,
        // и экземпляр у них должен быть один.
        let statsStore = ProcessingStatsStore()
        let processing = processingService
            ?? MediaProcessor(library: mediaLibrary, statsStore: statsStore)
        self.mediaLibrary = mediaLibrary
        self.processingService = processing
        self.previewRenderer = previewRenderer
        self.onboardingState = onboardingState

        // Тур — это корень первого запуска, а не окно поверх хаба: показать
        // его — значит начать приложение с другого мира, и заканчивается он
        // сменой корня, а не закрытием модалки.
        router = Router(
            root: onboardingState.hasSeenTour
                ? AnyRoute(HomeRoute.home)
                : AnyRoute(OnboardingRoute.tour)
        )

        // Плеер превью знает медиатеку, из которой пришёл файл: ролик она
        // отдаёт ссылкой, и другого экземпляра для этого заводить незачем.
        let mediaPlayer = Self.mediaPlayer(library: mediaLibrary)

        var resolvers: [RouteResolver] = [
            OnboardingFeature.resolver(state: onboardingState, home: HomeRoute.home),
            HomeFeature.resolver(tools: HomeTools.all, profile: ProfileRoute.profile),
            CompressFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                previewRenderer: previewRenderer,
                fileViewer: Self.fileViewer,
                mediaPlayer: mediaPlayer
            ),
            ConvertFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                previewRenderer: previewRenderer,
                fileViewer: Self.fileViewer,
                mediaPlayer: mediaPlayer
            ),
            AudioFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                fileViewer: Self.fileViewer,
                mediaPlayer: mediaPlayer
            ),
            ScanFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                mediaPlayer: mediaPlayer
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

    /// Чем показать готовый файл на экране просмотра. Собирается здесь,
    /// потому что AVKit живёт в модуле системной обработки, а знать про него
    /// разрешено только composition root.
    private static let fileViewer: MediaFileViewerFactory = { url in
        switch url.pathExtension.lowercased() {
        case "mov", "mp4", "m4v": AnyView(MediaVideoPlayer(url: url))
        case "m4a", "wav": AnyView(MediaAudioPlayer(url: url))
        // Снимку хватает кадра: своего экрана у него нет, а превью уже готово.
        default: nil
        }
    }

    /// Чем оживить превью файла при выборе. Играть есть что только у ролика
    /// и живого фото — остальному хватает кадра, и фабрика отвечает `nil`.
    private static func mediaPlayer(library: any MediaLibrary) -> MediaItemPlayerFactory {
        { item in
            guard item.kind == .video || item.isLivePhoto else { return nil }
            return AnyView(MediaItemPlayer(item: item, library: library))
        }
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
    /// в корень, стек и модалку, SwiftUI сам дорисовывает иерархию.
    func handle(_ deeplink: DeeplinkURL) {
        guard let destination = deeplinks.destination(for: deeplink) else { return }
        router.apply(destination)
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
