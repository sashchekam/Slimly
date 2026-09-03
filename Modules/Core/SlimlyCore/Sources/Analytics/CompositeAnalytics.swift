import Foundation

/// Несколько приёмников за одним протоколом.
///
/// Отладочная сборка пишет событие и в Firebase, и в консоль: увидеть, что
/// именно ушло, иначе можно только в веб-консоли и через сутки.
public struct CompositeAnalytics: AnalyticsService {
    private let services: [any AnalyticsService]

    public init(_ services: [any AnalyticsService]) {
        self.services = services
    }

    public func track(_ event: AnalyticsEvent) {
        for service in services {
            service.track(event)
        }
    }

    public func set(_ property: AnalyticsUserProperty, to value: String?) {
        for service in services {
            service.set(property, to: value)
        }
    }
}
