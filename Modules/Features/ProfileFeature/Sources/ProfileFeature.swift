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
        pro: any ProSubscription,
        localization: any LocalizationService,
        analytics: any AnalyticsService,
        debugMenu: (any Route)? = nil
    ) -> RouteResolver {
        let profileAnalytics = ProfileAnalytics(analytics: analytics)

        return RouteResolver(for: ProfileRoute.self) { route, router in
            switch route {
            case .profile:
                ProfileView(
                    viewModel: ProfileViewModel(
                        mediaLibrary: mediaLibrary,
                        processingService: processingService,
                        pro: pro,
                        localization: localization,
                        analytics: profileAnalytics,
                        debugMenu: debugMenu,
                        router: router
                    )
                )
            case .statistics:
                StatisticsView(
                    viewModel: StatisticsViewModel(
                        processingService: processingService,
                        analytics: profileAnalytics,
                        router: router
                    )
                )
            case .language:
                LanguageView(
                    viewModel: LanguageViewModel(
                        localization: localization,
                        analytics: profileAnalytics,
                        router: router
                    )
                )
            }
        }
    }
}
