import SlimlyCore

/// Аналитика хаба инструментов.
///
/// Хаб — единственное место, где виден спрос: какие карточки нажимают,
/// а какие лежат мёртвым грузом. Дальше начинается общий флоу, и всё,
/// что происходит внутри инструмента, пишет уже он сам.
public struct HomeAnalytics: FeatureAnalytics {
    public static let scope = "home"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Инструмент открыт с главной. Тот же инструмент открывается ссылкой
    /// и меню иконки, поэтому событие говорит именно про карточку.
    public func didOpenTool(_ tool: HomeTool) {
        track("tool_opened", ["tool": .text(Self.code(of: tool))])
    }

    /// Открыт профиль — экран статистики и настроек.
    public func didOpenProfile() {
        track("profile_opened")
    }

    /// Идентификатор карточки приходит из общего каталога инструментов,
    /// где он написан через дефис. В отчёте инструмент везде один и тот же
    /// «convert_photo», поэтому имя приводим к виду параметров флоу.
    private static func code(of tool: HomeTool) -> String {
        tool.id.replacingOccurrences(of: "-", with: "_")
    }
}
