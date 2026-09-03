import Foundation

/// Событие аналитики: имя и параметры.
///
/// Имя здесь уже готовое — с префиксом модуля и в змеином регистре. Собирает
/// его аналитика модуля (`FeatureAnalytics`), а не место вызова.
public struct AnalyticsEvent: Sendable, Hashable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(_ name: String, _ parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

/// Свойство пользователя — срез, по которому потом режется отчёт
/// и таргетируется удалённый конфиг.
public struct AnalyticsUserProperty: Sendable, Hashable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}
