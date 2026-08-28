import Foundation

/// Стирание типа маршрута.
///
/// `NavigationStack(path:)` и `.sheet(item:)` работают с одним конкретным типом,
/// а маршруты приходят из разных фич — поэтому в состоянии роутера лежит `AnyRoute`,
/// а резолвер фичи разворачивает его обратно в свой `enum`.
public struct AnyRoute: Hashable, Identifiable, Sendable {
    /// Исходный маршрут. Разворачивать — через ``unwrap(as:)``.
    public let base: any Route

    private let isEqual: @Sendable (any Route) -> Bool
    private let hashInto: @Sendable (inout Hasher) -> Void

    public init<R: Route>(_ route: R) {
        base = route
        isEqual = { ($0 as? R) == route }
        hashInto = { hasher in
            hasher.combine(ObjectIdentifier(R.self))
            hasher.combine(route)
        }
    }

    public var id: AnyRoute { self }

    public func unwrap<R: Route>(as type: R.Type = R.self) -> R? { base as? R }

    public func matches<R: Route>(_ type: R.Type) -> Bool { base is R }

    public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool { lhs.isEqual(rhs.base) }

    public func hash(into hasher: inout Hasher) { hashInto(&hasher) }
}

extension AnyRoute: CustomStringConvertible {
    public var description: String { "\(type(of: base)).\(base)" }
}
