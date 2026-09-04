import SlimlyCore

/// Аналитика вводного тура.
///
/// Тур — это первое, что видит человек, и единственное место, где отвал
/// стоит дорого: ушедший отсюда не увидел ни одного инструмента. Поэтому
/// событий два — переход по страницам и то, чем тур закончился.
public struct OnboardingAnalytics: FeatureAnalytics {
    public static let scope = "onboarding"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Открыта следующая страница тура. Номер человеческий, с единицы:
    /// в отчёте он читается как «докрутили до третьей».
    public func didOpenPage(_ index: Int) {
        track("page_opened", ["page": .int(index + 1)])
    }

    /// Тур закончен. `skipped` отделяет дочитавших от нажавших «Пропустить»:
    /// экран приложения оба увидят, но пришли к нему по-разному.
    public func didFinish(page index: Int, skipped: Bool) {
        track("finished", ["page": .int(index + 1), "skipped": .flag(skipped)])
    }
}
