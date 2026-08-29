import CompressFeatureInterface
import SlimlyCore
import SlimlyNavigation

/// Точка сборки фичи сжатия.
///
/// Переход в профиль приходит замыканием, а не ссылкой на таб-бар: фича
/// умеет «показать профиль», но ничего не знает ни про соседний модуль,
/// ни про то, как устроена корневая навигация.
public enum CompressFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        compressionService: any CompressionService,
        showProfile: @escaping @MainActor () -> Void
    ) -> RouteResolver {
        RouteResolver(for: CompressRoute.self) { route, router in
            switch route {
            case .gallery:
                GalleryView(
                    viewModel: GalleryViewModel(
                        mediaLibrary: mediaLibrary,
                        compressionService: compressionService,
                        router: router
                    )
                )

            case let .setup(items, options):
                SetupView(viewModel: SetupViewModel(items: items, options: options, router: router))

            case let .run(items, options):
                RunView(
                    viewModel: RunViewModel(
                        items: items,
                        options: options,
                        compressionService: compressionService,
                        router: router
                    )
                )

            case let .result(outcome):
                ResultView(
                    viewModel: ResultViewModel(
                        outcome: outcome,
                        router: router,
                        showProfile: showProfile
                    )
                )
            }
        }
    }
}
