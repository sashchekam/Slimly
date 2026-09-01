import SlimlyNavigation

/// Куда ведёт шаг общего флоу.
///
/// Маршрут не знает про способ показа: настройки сжатия приезжают шторкой,
/// а настройки конвертации — экраном в стеке. Решает это фича, которая
/// собирает шаг, а сам шаг просто исполняет её решение.
public enum FlowDestination: Sendable {
    case push(any Route)
    case present(any Route)
    /// Поверх всего экрана — для того, у чего своя полноэкранная жизнь:
    /// камера, системный просмотрщик документа.
    case cover(any Route)
}

public extension Router {
    /// Исполнить решение фичи о способе показа.
    ///
    /// Разбор `FlowDestination` одинаков у всех шагов, и держать его копию
    /// в каждой ViewModel значило бы трижды описывать одно и то же.
    func go(to destination: FlowDestination) {
        switch destination {
        case let .push(route): push(route)
        case let .present(route): present(route)
        case let .cover(route): cover(route)
        }
    }
}
