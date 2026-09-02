import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum ProfileFeature {
    /// `debugMenu` приходит готовым маршрутом, а не типом: профиль не должен
    /// знать, что за модуль стоит за отладочным меню и есть ли он в сборке.
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        debugMenu: (any Route)? = nil
    ) -> RouteResolver {
        RouteResolver(for: ProfileRoute.self) { route, router in
            switch route {
            case .profile:
                ProfileView(
                    viewModel: ProfileViewModel(
                        mediaLibrary: mediaLibrary,
                        processingService: processingService,
                        debugMenu: debugMenu,
                        router: router
                    )
                )
            }
        }
    }
}
