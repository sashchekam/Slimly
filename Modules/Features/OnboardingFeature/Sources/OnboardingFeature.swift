import OnboardingFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum OnboardingFeature {
    /// `home` приходит готовым маршрутом, а не типом: тур заканчивается
    /// сменой корня, но какая фича стоит за главным экраном — не его дело.
    @MainActor
    public static func resolver(
        state: any OnboardingState,
        home: any Route,
        analytics: any AnalyticsService
    ) -> RouteResolver {
        RouteResolver(for: OnboardingRoute.self) { route, router in
            switch route {
            case .tour:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        state: state,
                        home: home,
                        analytics: OnboardingAnalytics(analytics: analytics),
                        router: router
                    )
                )
            }
        }
    }
}
