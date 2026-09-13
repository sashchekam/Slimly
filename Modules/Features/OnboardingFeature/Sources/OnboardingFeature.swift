import OnboardingFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum OnboardingFeature {
    /// `home` и `paywall` приходят готовыми маршрутами, а не типами: тур
    /// заканчивается сменой корня и предложением тарифа, но какие фичи
    /// за ними стоят — не его дело.
    @MainActor
    public static func resolver(
        state: any OnboardingState,
        home: any Route,
        paywall: @escaping () -> (any Route)? = { nil },
        analytics: any AnalyticsService
    ) -> RouteResolver {
        RouteResolver(for: OnboardingRoute.self) { route, router in
            switch route {
            case .tour:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        state: state,
                        home: home,
                        paywall: paywall,
                        analytics: OnboardingAnalytics(analytics: analytics),
                        router: router
                    )
                )
            }
        }
    }
}
