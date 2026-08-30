import DebugFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum DebugFeature {
    /// Хранилище статистики приходит тем же экземпляром, что и у обработчика:
    /// сброс из меню должен обнулять те цифры, которые показывает профиль,
    /// а не свою копию.
    @MainActor
    public static func resolver(
        settings: DebugSettings,
        statsStore: ProcessingStatsStore,
        environment: AppEnvironment = .current
    ) -> RouteResolver {
        RouteResolver(for: DebugRoute.self) { route, router in
            switch route {
            case .menu:
                DebugMenuView(
                    viewModel: DebugMenuViewModel(
                        settings: settings,
                        statsStore: statsStore,
                        environment: environment,
                        router: router
                    )
                )
            }
        }
    }
}
