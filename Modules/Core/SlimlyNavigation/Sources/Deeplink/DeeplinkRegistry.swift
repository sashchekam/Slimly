import Foundation
import SlimlyCore

/// Куда ведёт диплинк: стек маршрутов и, если нужно, модалка поверх него.
///
/// Обычная запись — литерал массива, поэтому таблица ссылок читается как
/// список маршрутов. Модалка нужна там, где экран и с хаба открывается
/// шторкой: ссылка не должна показывать его иначе, чем кнопка.
public struct DeeplinkDestination: Sendable, ExpressibleByArrayLiteral {
    /// Первый маршрут становится корнем слоя, остальные ложатся в стек.
    public let routes: [any Route]
    /// Что показать шторкой поверх стека.
    public let sheet: (any Route)?

    public init(routes: [any Route], sheet: (any Route)? = nil) {
        self.routes = routes
        self.sheet = sheet
    }

    public init(arrayLiteral elements: any Route...) {
        self.init(routes: elements)
    }

    public var isEmpty: Bool { routes.isEmpty && sheet == nil }
}

/// Превращает разобранный диплинк в состояние навигации.
///
/// Первый мэппер, вернувший непустой результат, выигрывает. Сами шаблоны URL
/// живут в App: только там известны маршруты всех фич сразу.
public struct DeeplinkRegistry: Sendable {
    public typealias Mapper = @Sendable (DeeplinkURL) -> DeeplinkDestination?

    private let mappers: [Mapper]

    public init(_ mappers: [Mapper]) {
        self.mappers = mappers
    }

    public func destination(for deeplink: DeeplinkURL) -> DeeplinkDestination? {
        for mapper in mappers {
            if let destination = mapper(deeplink), !destination.isEmpty { return destination }
        }
        return nil
    }
}

public extension Router {
    /// Диплинк — это одно присвоение состояния: стек раскладывается в слой,
    /// модалка встаёт поверх него.
    func apply(_ destination: DeeplinkDestination) {
        replace(with: destination.routes)
        if let sheet = destination.sheet {
            present(sheet)
        }
    }
}
