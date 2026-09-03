import Foundation

/// Значение параметра события.
///
/// Перечисление, а не `Any`: событие уходит в аналитику из любого места
/// приложения, поэтому обязано быть `Sendable`, — а ещё системы аналитики
/// принимают лишь несколько типов, и лучше не пропустить чужой на компиляции,
/// чем терять параметр молча в рантайме.
public enum AnalyticsValue: Sendable, Hashable {
    case text(String)
    case int(Int)
    case double(Double)
    case flag(Bool)
}

// Литералы избавляют место вызова от обёрток: словарь параметров пишется
// как обычный — `["count": 3, "level": "high"]`.
extension AnalyticsValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .text(value)
    }
}

extension AnalyticsValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension AnalyticsValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnalyticsValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .flag(value)
    }
}
