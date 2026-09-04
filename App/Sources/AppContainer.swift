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
import SlimlyFirebase
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
    let debugSettings: DebugSettings
    /// Отметка о показанном туре. Живёт здесь, а не в фиче: с неё начинается
    /// выбор корня, и тот же экземпляр потом ставит отметку.
    let onboardingState: any OnboardingState
    /// Общая аналитика приложения. Фича её не создаёт: она заводит свою
    /// поверх этой и получает её параметром резолвера.
    let analytics: any AnalyticsService
    /// Значения, которыми можно управлять без выпуска сборки.
    let remoteConfig: any RemoteConfigService

    /// События самого приложения — то, что случается вне экранов.
    private let appAnalytics: AppAnalytics

    // MARK: Навигация

    let router: Router
    let registry: RouteRegistry

    private let deeplinks: DeeplinkRegistry

    /// Первый экран показан: до этого момента ссылкам открывать нечего.
    private var isScreenReady = false
    /// Ссылка, пришедшая раньше первого экрана. Хранится последняя: нажатие
    /// в меню иконки одно, и открыть оно должно один инструмент.
    private var deferredDeeplink: (deeplink: DeeplinkURL, source: DeeplinkSource)?

    /// Обработчику нужна та же медиатека, из которой выбирали файлы:
    /// он забирает у неё оригиналы и возвращает результат. Поэтому сервис
    /// собирается после библиотеки, а не значением по умолчанию.
    init(
        mediaLibrary: any MediaLibrary = PhotosMediaLibrary(),
        processingService: (any MediaProcessingService)? = nil,
        previewRenderer: any MediaPreviewRenderer = SystemMediaPreviewRenderer(),
        onboardingState: any OnboardingState = StoredOnboardingState(),
        firebase: FirebaseServices = FirebaseServices()
    ) {
        // Хранилище статистики создаётся здесь, а не внутри обработчика:
        // отладочное меню сбрасывает те же цифры, что показывает профиль,
        // и экземпляр у них должен быть один.
        let statsStore = ProcessingStatsStore()
        let processing = processingService
            ?? MediaProcessor(library: mediaLibrary, statsStore: statsStore)
        // Хранилище одно на меню и на конфиг: подмены значений пишет меню,
        // а читает их конфиг сам, без посредника между ними.
        let storage = DefaultsStorage()
        debugSettings = DebugSettings(storage: storage)
        self.mediaLibrary = mediaLibrary
        self.processingService = processing
        self.previewRenderer = previewRenderer
        self.onboardingState = onboardingState

        // В отладочной сборке событие дублируется в консоль: иначе увидеть,
        // что именно ушло, можно только в веб-консоли и только назавтра.
        #if DEBUG
        analytics = CompositeAnalytics([firebase.analytics, ConsoleAnalytics()])
        #else
        analytics = firebase.analytics
        #endif
        // Подмены отладочного меню ложатся поверх источника и действуют
        // на всё приложение: проверять флаг имеет смысл на настоящих экранах,
        // а не только на том, где его подменили.
        #if DEBUG
        remoteConfig = OverridingRemoteConfig(base: firebase.remoteConfig, storage: storage)
        #else
        remoteConfig = firebase.remoteConfig
        #endif
        appAnalytics = AppAnalytics(analytics: analytics)

        // Свежие значения нужны первому же экрану, но ждать их старт не
        // должен: до ответа сети работают умолчания ключей.
        let remote = firebase.remoteConfig
        Task { await remote.refresh() }

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
        let viewers = MediaViewers(
            file: Self.fileViewer,
            player: Self.mediaPlayer(library: mediaLibrary)
        )

        var resolvers: [RouteResolver] = [
            OnboardingFeature.resolver(
                state: onboardingState,
                home: HomeRoute.home,
                analytics: analytics
            ),
            HomeFeature.resolver(
                tools: HomeTools.all,
                profile: ProfileRoute.profile,
                analytics: analytics
            ),
            CompressFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                previewRenderer: previewRenderer,
                analytics: analytics,
                viewers: viewers
            ),
            ConvertFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                previewRenderer: previewRenderer,
                analytics: analytics,
                viewers: viewers
            ),
            AudioFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                analytics: analytics,
                viewers: viewers
            ),
            ScanFeature.resolver(
                mediaLibrary: mediaLibrary,
                processingService: processing,
                analytics: analytics,
                viewers: viewers
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
            DebugFeature.resolver(
                settings: debugSettings,
                statsStore: statsStore,
                onboardingState: onboardingState,
                remoteConfig: firebase.remoteConfig
            )
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
    ///
    /// До конца заставки ссылка только откладывается: при холодном старте
    /// быстрое действие приходит раньше первого экрана, и открытая сразу
    /// шторка выехала бы поверх заставки.
    func handle(_ deeplink: DeeplinkURL, from source: DeeplinkSource = .url) {
        guard isScreenReady else {
            deferredDeeplink = (deeplink, source)
            return
        }
        guard let destination = deeplinks.destination(for: deeplink) else {
            appAnalytics.didFailDeeplink(deeplink)
            return
        }
        router.apply(destination)
        appAnalytics.didOpenDeeplink(deeplink, from: source)
    }

    /// Заставка ушла, первый экран на месте — отложенная ссылка открывается.
    func screenDidAppear() {
        isScreenReady = true
        guard let deferred = deferredDeeplink else { return }
        deferredDeeplink = nil
        handle(deferred.deeplink, from: deferred.source)
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
