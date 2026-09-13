import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum ProfileFeature {
    /// `paywall` и `debugMenu` приходят готовыми маршрутами, а не типами:
    /// профиль не должен знать, какие модули за ними стоят и есть ли они
    /// в сборке вообще.
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        pro: any ProSubscription,
        localization: any LocalizationService,
        analytics: any AnalyticsService,
        paywall: (any Route)? = nil,
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
                        paywall: paywall,
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
