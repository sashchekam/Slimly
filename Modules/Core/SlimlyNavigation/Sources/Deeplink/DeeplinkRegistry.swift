import Foundation
import SlimlyCore

/// Превращает разобранный диплинк в набор маршрутов.
///
/// Первый мэппер, вернувший непустой результат, выигрывает. Сами шаблоны URL
/// живут в App: только там известны маршруты всех фич сразу.
public struct DeeplinkRegistry: Sendable {
    public typealias Mapper = @Sendable (DeeplinkURL) -> [any Route]?

    private let mappers: [Mapper]

    public init(_ mappers: [Mapper]) {
        self.mappers = mappers
    }

    public func routes(for deeplink: DeeplinkURL) -> [any Route]? {
        for mapper in mappers {
            if let routes = mapper(deeplink), !routes.isEmpty { return routes }
        }
        return nil
    }
}
