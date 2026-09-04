import Foundation

/// Приёмник, который никуда не отправляет: он складывает отправленное
/// в ``AnalyticsLog``, откуда это показывает отладочное меню.
///
/// В отладочной сборке стоит рядом с настоящей аналитикой, в
/// ``CompositeAnalytics``: событие уходит наружу и одновременно остаётся
/// на устройстве, где его видно сразу, а не через сутки в веб-консоли.
public struct RecordingAnalytics: AnalyticsService {
    private let log: AnalyticsLog

    public init(log: AnalyticsLog) {
        self.log = log
    }

    public func track(_ event: AnalyticsEvent) {
        append(AnalyticsRecord(name: event.name, content: .event(parameters: event.parameters)))
    }

    public func set(_ property: AnalyticsUserProperty, to value: String?) {
        append(AnalyticsRecord(name: property.name, content: .property(value: value)))
    }

    /// Отправляют аналитику откуда угодно, а журнал живёт на главном потоке —
    /// там же, где экран, который его показывает.
    private func append(_ record: AnalyticsRecord) {
        Task { @MainActor in
            log.append(record)
        }
    }
}
