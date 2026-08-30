import HomeFeatureInterface
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

    public init(
        id: String,
        title: String,
        subtitle: String,
        icon: SlimlyIcon.Kind,
        route: any Route
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.route = route
    }
}

public enum HomeFeature {
    @MainActor
    public static func resolver(tools: [HomeTool], profile: any Route) -> RouteResolver {
        RouteResolver(for: HomeRoute.self) { route, router in
            switch route {
            case .home:
                HomeView(
                    viewModel: HomeViewModel(tools: tools, profile: profile, router: router)
                )
            }
        }
    }
}
