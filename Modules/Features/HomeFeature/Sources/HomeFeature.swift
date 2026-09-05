import HomeFeatureInterface
import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation

/// Карточка инструмента на главной.
///
/// Маршрут приходит готовым значением: главный экран не знает, какие
/// инструменты существуют и в каких модулях живут, — список собирает App.
/// Поэтому новый инструмент не требует правок в этой фиче.
public struct HomeTool: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: SlimlyIcon.Kind
    public let route: any Route
    /// Как открывать инструмент. Большинство уходит экраном в стек, но там,
    /// где первый шаг — короткий выбор, уместнее шторка над хабом.
    public let presentation: RoutePresentation

    public init(
        id: String,
        title: String,
        subtitle: String,
        icon: SlimlyIcon.Kind,
        route: any Route,
        presentation: RoutePresentation = .push
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.route = route
        self.presentation = presentation
    }
}

public enum HomeFeature {
    @MainActor
    public static func resolver(
        tools: @escaping @MainActor () -> [HomeTool],
        profile: any Route,
        analytics: any AnalyticsService
    ) -> RouteResolver {
        RouteResolver(for: HomeRoute.self) { route, router in
            switch route {
            case .home:
                HomeView(
                    viewModel: HomeViewModel(
                        tools: tools,
                        profile: profile,
                        analytics: HomeAnalytics(analytics: analytics),
                        router: router
                    )
                )
            }
        }
    }
}
