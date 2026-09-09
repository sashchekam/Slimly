import DebugFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum DebugFeature {
    /// Хранилище статистики приходит тем же экземпляром, что и у обработчика:
    /// сброс из меню должен обнулять те цифры, которые показывает профиль,
    /// а не свою копию. По той же причине отметка о туре — тот экземпляр,
    /// по которому старт выбирает корень.
    ///
    /// - Parameter remoteConfig: источник значений без подмен поверх — экран
    ///   конфига показывает, что реально приехало с сервера, и подмену рядом.
    /// - Parameter analyticsLog: тот же журнал, в который пишет аналитика
    ///   сборки: меню показывает отправленное, а не свою копию.
    @MainActor
    public static func resolver(
        settings: DebugSettings,
        statsStore: ProcessingStatsStore,
        onboardingState: any OnboardingState,
        remoteConfig: any RemoteConfigService,
        analyticsLog: AnalyticsLog,
        environment: AppEnvironment = .current
    ) -> RouteResolver {
        RouteResolver(for: DebugRoute.self) { route, router in
            switch route {
            case .menu:
                DebugMenuView(
                    viewModel: DebugMenuViewModel(
                        settings: settings,
                        statsStore: statsStore,
                        onboardingState: onboardingState,
                        analyticsLog: analyticsLog,
                        environment: environment,
                        router: router
                    )
                )
            case .remoteConfig:
                DebugRemoteConfigView(
                    viewModel: DebugRemoteConfigViewModel(
                        settings: settings,
                        remoteConfig: remoteConfig,
                        router: router
                    )
                )
            case let .remoteConfigValue(name):
                DebugRemoteConfigValueView(
                    viewModel: DebugRemoteConfigValueViewModel(
                        name: name,
                        settings: settings,
                        remoteConfig: remoteConfig,
                        router: router
                    )
                )
            case .analytics:
                DebugAnalyticsView(
                    viewModel: DebugAnalyticsViewModel(log: analyticsLog, router: router)
                )
            }
        }
    }
}
