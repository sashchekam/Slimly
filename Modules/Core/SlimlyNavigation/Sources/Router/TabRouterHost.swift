import SwiftUI

/// Рендерит табы: по хосту на таб, панель — снизу.
///
/// Стеки всех табов держатся живыми, поэтому возврат в таб возвращает
/// его историю, а не корень. Панель рисует вызывающая сторона: её вид —
/// продуктовая деталь, а не забота навигации.
///
/// Панель занимает собственную полосу, а не накрывает контент через
/// `safeAreaInset`: `NavigationStack` внутри не наследует safe area,
/// добавленную снаружи, и всё, что экран сам вешает на нижний край —
/// кнопка действия, баннер — уезжало бы под панель.
public struct TabRouterHost<TabBar: View>: View {
    @State
    private var tabRouter: TabRouter
    private let registry: RouteRegistry
    private let tabBar: (TabRouter) -> TabBar

    public init(
        tabRouter: TabRouter,
        registry: RouteRegistry,
        @ViewBuilder tabBar: @escaping (TabRouter) -> TabBar
    ) {
        _tabRouter = State(wrappedValue: tabRouter)
        self.registry = registry
        self.tabBar = tabBar
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(tabRouter.items) { item in
                    let isSelected = item.id == tabRouter.selection

                    RouterHost(router: tabRouter.router(for: item.id), registry: registry)
                        .opacity(isSelected ? 1 : 0)
                        .allowsHitTesting(isSelected)
                        .accessibilityHidden(!isSelected)
                }
            }

            tabBar(tabRouter)
        }
        .environment(tabRouter)
    }
}
