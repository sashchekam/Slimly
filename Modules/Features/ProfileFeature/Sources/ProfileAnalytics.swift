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

    /// Нажали на предложение тарифа в плашке профиля.
    ///
    /// Второй вход в подписку рядом с тем, что в шаге выбора файлов: там
    /// в предел упираются, а сюда приходят посмотреть на себя — и спрос
    /// из этих двух мест означает разное.
    public func didOpenProOffer() {
        track("pro_offer_opened")
    }

    /// Сменили срез времени. Умолчание — 90 дней; если его почти всегда
    /// меняют, значит выбрано неверно.
    public func didChangeRange(_ range: StatsRange) {
        track("statistics_range_changed", ["range": .text(Self.code(of: range))])
    }

    /// Язык интерфейса выбран вручную или возвращён к телефонному.
    ///
    /// Интересна не сама смена, а то, каким языкам не хватает перевода:
    /// уход с языка телефона значит, что наш перевод человека не устроил.
    public func didChangeLanguage(to language: AppLanguage?) {
        track("language_changed", ["language": .text(language?.code ?? "system")])
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
