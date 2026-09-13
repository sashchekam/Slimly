import PaywallFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum PaywallFeature {
    /// Магазин и тариф приходят протоколами: за ними стоит RevenueCat,
    /// но фича об этом не знает — и без ключей магазина собирается так же.
    @MainActor
    public static func resolver(
        purchases: any PurchaseService,
        pro: any ProSubscription,
        analytics: any AnalyticsService
    ) -> RouteResolver {
        let paywallAnalytics = PaywallAnalytics(analytics: analytics)

        return RouteResolver(for: PaywallRoute.self) { route, router in
            switch route {
            case let .paywall(source):
                PaywallView(
                    viewModel: PaywallViewModel(
                        source: source,
                        purchases: purchases,
                        pro: pro,
                        analytics: paywallAnalytics,
                        router: router
                    )
                )
            }
        }
    }
}
