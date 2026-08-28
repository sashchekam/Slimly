import SwiftUI

/// Знает, как построить экран по маршрутам одного типа.
///
/// Резолвер объявляет сама фича (она единственная знает свои View и ViewModel),
/// а зависимости в него прокидывает App при сборке реестра.
@MainActor
public struct RouteResolver {
    let canHandle: (AnyRoute) -> Bool
    let build: (AnyRoute, Router) -> AnyView

    public init<R: Route, Content: View>(
        for routeType: R.Type,
        @ViewBuilder build: @escaping (R, Router) -> Content
    ) {
        canHandle = { $0.matches(R.self) }
        self.build = { anyRoute, router in
            guard let route = anyRoute.unwrap(as: R.self) else { return AnyView(EmptyView()) }
            return AnyView(build(route, router))
        }
    }
}

/// Реестр «маршрут → экран». Собирается в App — это единственное место,
/// где известны все фичи сразу.
@MainActor
public struct RouteRegistry {
    private let resolvers: [RouteResolver]

    public init(_ resolvers: [RouteResolver]) {
        self.resolvers = resolvers
    }

    public func view(for route: AnyRoute, router: Router) -> AnyView {
        guard let resolver = resolvers.first(where: { $0.canHandle(route) }) else {
            return AnyView(UnresolvedRouteView(route: route))
        }
        return resolver.build(route, router)
    }
}

/// Заглушка на случай маршрута, для которого забыли зарегистрировать резолвер.
/// Лучше видимый экран с текстом, чем пустота или креш в проде.
struct UnresolvedRouteView: View {
    let route: AnyRoute

    var body: some View {
        ContentUnavailableView(
            "Экран не найден",
            systemImage: "questionmark.square.dashed",
            description: Text("Не зарегистрирован резолвер для \(route.description)")
        )
    }
}
