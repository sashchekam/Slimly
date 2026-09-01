/// Способ показа маршрута.
///
/// Маршрут о нём не знает: один и тот же экран можно и запушить, и поднять
/// шторкой, и показать поверх всего — выбирает тот, кто открывает.
public enum RoutePresentation: Sendable {
    case push
    case sheet
    /// Поверх всего экрана — для того, у чего своя полноэкранная жизнь:
    /// камера, системный просмотрщик документа.
    case cover
}

public extension Router {
    func show(_ route: some Route, as presentation: RoutePresentation) {
        switch presentation {
        case .push: push(route)
        case .sheet: present(route)
        case .cover: cover(route)
        }
    }
}
