import SlimlyCore

/// Аналитика профиля.
///
/// Профиль — единственный экран без работы: сюда приходят посмотреть на себя.
/// Отсюда и вопросы к нему: доходят ли вообще до подробной статистики
/// и какой срез времени человеку интересен.
public struct ProfileAnalytics: FeatureAnalytics {
    public static let scope = "profile"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Открыт разбор по инструментам. Источник важнее самого факта: плитка
    /// в карточке и ссылка под ней ведут в одно место, но плитку нажимают
    /// с вопросом про конкретный инструмент.
    public func didOpenStatistics(from source: StatisticsSource) {
        track("statistics_opened", ["source": .text(source.rawValue)])
    }

    /// Сменили срез времени. Умолчание — 90 дней; если его почти всегда
    /// меняют, значит выбрано неверно.
    public func didChangeRange(_ range: StatsRange) {
        track("statistics_range_changed", ["range": .text(Self.code(of: range))])
    }

    private static func code(of range: StatsRange) -> String {
        switch range {
        case .month: "days_30"
        case .quarter: "days_90"
        case .allTime: "all_time"
        }
    }
}

/// Откуда пришли в подробную статистику.
public enum StatisticsSource: String, Sendable {
    /// Плитка инструмента в карточке «чем вы пользовались».
    case tile
    /// Ссылка «Вся статистика» под плитками.
    case link
}
