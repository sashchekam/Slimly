import Foundation
import Observation

/// Состояние навигации одного слоя презентации.
///
/// Один `Router` = один `NavigationStack`. Каждая модалка получает **собственный**
/// дочерний роутер, поэтому иерархия роутеров повторяет иерархию презентаций:
/// «стек внутри шита» и «модалка поверх модалки» работают без спецслучаев,
/// а `dismissToRoot()` доступен с любой глубины.
@MainActor
@Observable
public final class Router {
    /// Корень стека. Меняется, когда меняется «мир»: логин → главный экран.
    public private(set) var root: AnyRoute

    /// Всё, что лежит поверх корня.
    public var path: [AnyRoute] = []

    public var sheet: AnyRoute?
    public var fullScreenCover: AnyRoute?

    /// Роутер слоя, который презентовал этот. `nil` — у корневого.
    @ObservationIgnored
    public private(set) weak var parent: Router?

    /// Маршрут, которым этот слой был показан у родителя.
    /// Нужен, чтобы ``dismiss()`` погасил именно свой слот, а не соседний.
    @ObservationIgnored
    private let presentedRoute: AnyRoute?

    public init(root: AnyRoute, parent: Router? = nil) {
        self.root = root
        self.parent = parent
        presentedRoute = parent == nil ? nil : root
    }

    public convenience init(root: some Route, parent: Router? = nil) {
        self.init(root: AnyRoute(root), parent: parent)
    }

    /// Самый верхний роутер в цепочке презентаций.
    public var topmost: Router { parent?.topmost ?? self }
}

// MARK: - Навигация внутри слоя

public extension Router {
    func push(_ route: some Route) {
        path.append(AnyRoute(route))
    }

    func push(_ routes: [any Route]) {
        path.append(contentsOf: routes.map { AnyRoute($0) })
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Задать стек поверх текущего корня целиком (диплинк внутрь одного «мира»).
    func setPath(_ routes: [any Route]) {
        path = routes.map { AnyRoute($0) }
    }

    /// Сменить корень слоя, стек при этом сбрасывается.
    func setRoot(_ route: some Route) {
        root = AnyRoute(route)
        path.removeAll()
    }

    /// Полностью заменить содержимое слоя: первый маршрут становится корнем,
    /// остальные ложатся в стек. Основной приём для диплинков.
    func replace(with routes: [any Route]) {
        guard let first = routes.first else { return }
        dismissModals()
        root = AnyRoute(first)
        path = routes.dropFirst().map { AnyRoute($0) }
    }
}

// MARK: - Модалки

public extension Router {
    func present(_ route: some Route) {
        sheet = AnyRoute(route)
    }

    func cover(_ route: some Route) {
        fullScreenCover = AnyRoute(route)
    }

    /// Закрыть модалки, показанные из этого слоя.
    func dismissModals() {
        sheet = nil
        fullScreenCover = nil
    }

    /// Закрыть сам этот слой у родителя. Для корневого роутера — no-op.
    func dismiss() {
        guard let parent, let presentedRoute else { return }
        if parent.sheet == presentedRoute {
            parent.sheet = nil
        } else if parent.fullScreenCover == presentedRoute {
            parent.fullScreenCover = nil
        }
    }

    /// Свернуть всю навигацию до корня приложения: закрыть модалки вверх по цепочке
    /// и сбросить стек самого верхнего роутера.
    func dismissToRoot() {
        var current: Router? = self
        while let router = current, router.parent != nil {
            router.dismiss()
            current = router.parent
        }
        let top = current ?? self
        top.dismissModals()
        top.popToRoot()
    }

    /// Перезапуск навигации с новым корнем — логин, логаут, смена аккаунта.
    func restart(with route: some Route) {
        let top = topmost
        dismissToRoot()
        top.setRoot(route)
    }
}
