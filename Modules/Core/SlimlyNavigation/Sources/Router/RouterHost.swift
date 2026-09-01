import SwiftUI

/// Рендерит состояние роутера: стек — в `NavigationStack`, модалки — в `.sheet`
/// и `.fullScreenCover`. Внутри модалки поднимается такой же хост со своим
/// роутером, поэтому вложенность произвольная.
public struct RouterHost: View {
    @State private var router: Router
    private let registry: RouteRegistry

    public init(router: Router, registry: RouteRegistry) {
        _router = State(wrappedValue: router)
        self.registry = registry
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            registry.view(for: router.root, router: router)
                .navigationDestination(for: AnyRoute.self) { route in
                    registry.view(for: route, router: router)
                }
        }
        .environment(router)
        // Идентичность слоя — его маршрут: без неё SwiftUI переиспользует
        // состояние хоста между шитом и кавером, и модалка, открытая взамен
        // закрывающейся, приезжает с чужим корнем.
        .sheet(item: $router.sheet) { route in
            ModalRouterHost(route: route, parent: router, registry: registry)
                .id(route)
        }
        .fullScreenCover(item: $router.fullScreenCover) { route in
            ModalRouterHost(route: route, parent: router, registry: registry)
                .id(route)
        }
    }
}

/// Держит дочерний роутер модалки живым между перерисовками контента.
private struct ModalRouterHost: View {
    @State private var router: Router
    @State private var sheetHeight: CGFloat?
    private let registry: RouteRegistry

    init(route: AnyRoute, parent: Router, registry: RouteRegistry) {
        _router = State(wrappedValue: Router(root: route, parent: parent))
        self.registry = registry
    }

    var body: some View {
        RouterHost(router: router, registry: registry)
            .onPreferenceChange(SheetHeightKey.self) { height in
                if let height { sheetHeight = height }
            }
            .presentationDetents(sheetHeight.map { [.height($0)] } ?? [.large])
    }
}
