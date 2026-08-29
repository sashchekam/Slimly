import Foundation
import Observation

/// Состояние таб-бара.
///
/// Таб — это тоже навигация, поэтому он состояние, а не контрол: выбранный
/// таб можно поменять из диплинка или из другой фичи, ничего не «нажимая».
/// У каждого таба свой ``Router``, поэтому стеки табов независимы и
/// переключение не сбрасывает историю.
@MainActor
@Observable
public final class TabRouter {
    public struct Item: Identifiable, Sendable {
        public let id: String
        public let root: AnyRoute

        public init(id: String, root: AnyRoute) {
            self.id = id
            self.root = root
        }

        public init(id: String, root: some Route) {
            self.init(id: id, root: AnyRoute(root))
        }
    }

    public let items: [Item]
    public var selection: String

    /// Роутеры создаются по требованию и живут до конца сессии.
    /// `lazy` здесь запрещён: `@Observable` не переносит ленивых свойств.
    @ObservationIgnored
    private var routers: [String: Router] = [:]

    public init(items: [Item], selection: String? = nil) {
        precondition(!items.isEmpty, "Таб-бар без табов не имеет смысла")
        self.items = items
        self.selection = selection ?? items[0].id
    }

    public func router(for id: String) -> Router {
        if let existing = routers[id] { return existing }

        let root = items.first { $0.id == id }?.root ?? items[0].root
        let router = Router(root: root)
        routers[id] = router
        return router
    }

    public var selectedRouter: Router { router(for: selection) }

    /// Повторное нажатие на активный таб сворачивает его стек к корню —
    /// так ведут себя системные табы, и пользователи этого ждут.
    public func select(_ id: String) {
        if id == selection {
            router(for: id).dismissToRoot()
        } else {
            selection = id
        }
    }
}
