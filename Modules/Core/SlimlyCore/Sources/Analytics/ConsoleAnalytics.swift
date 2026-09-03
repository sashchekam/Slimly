import OSLog

/// Событие в системный лог — то же имя и те же параметры, что уйдут наружу.
///
/// Категория отдельная: в Console.app по ней отфильтровывается вся аналитика
/// сборки, не перемешиваясь с остальными сообщениями приложения.
public struct ConsoleAnalytics: AnalyticsService {
    private let logger = Logger(subsystem: "com.slimly", category: "analytics")

    public init() { }

    public func track(_ event: AnalyticsEvent) {
        logger.debug("→ \(event.name, privacy: .public) \(Self.described(event.parameters), privacy: .public)")
    }

    public func set(_ property: AnalyticsUserProperty, to value: String?) {
        logger.debug("· \(property.name, privacy: .public) = \(value ?? "—", privacy: .public)")
    }

    /// Параметры печатаются по алфавиту: одинаковые события должны выглядеть
    /// в логе одинаково, иначе их не сравнить глазами.
    private static func described(_ parameters: [String: AnalyticsValue]) -> String {
        guard !parameters.isEmpty else { return "" }

        let pairs = parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\(text(of: $0.value))" }
        return "[\(pairs.joined(separator: ", "))]"
    }

    private static func text(of value: AnalyticsValue) -> String {
        switch value {
        case let .text(text): text
        case let .int(number): String(number)
        case let .double(number): String(number)
        case let .flag(flag): String(flag)
        }
    }
}
