import SlimlyCore

/// Аналитика скана.
///
/// Единственный инструмент со своим началом: у скана есть выбор источника
/// и съёмка страниц, которых нет ни у кого больше. Дальше начинается общий
/// флоу и его события `flow_*`.
public struct ScanAnalytics: FeatureAnalytics {
    public static let scope = "scan"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Откуда берут страницы. Камера и галерея — разные сценарии: документ
    /// снимают на месте, а из галереи собирают то, что сняли раньше.
    public func didPickSource(_ source: ScanSource) {
        track("source_picked", ["source": .text(source.rawValue)])
    }

    /// Съёмка закончена, страницы уходят дальше. Режим — тот, что стоял
    /// на последнем кадре: по нему видно, доверяют ли автоспуску.
    public func didCapturePages(count: Int, isAutomatic: Bool) {
        track(
            "pages_captured",
            [
                "count": .int(count),
                "mode": .text(isAutomatic ? "auto" : "manual"),
            ]
        )
    }

    /// Из камеры вышли, снятое выброшено. Число страниц отделяет
    /// передумавшего на первом кадре от того, у кого съёмка не задалась.
    public func didCancelCamera(count: Int) {
        track("camera_cancelled", ["count": .int(count)])
    }

    /// Границы страниц приняты. `edited` и `missed` — оценка автоматики
    /// человеком: сколько рамок пришлось поправить и на скольких страницах
    /// лист вообще не нашёлся.
    public func didConfirmBounds(count: Int, edited: Int, missed: Int) {
        track(
            "bounds_confirmed",
            [
                "count": .int(count),
                "edited": .int(edited),
                "missed": .int(missed),
            ]
        )
    }
}

/// Откуда берутся страницы документа.
public enum ScanSource: String, Sendable {
    case camera
    case gallery
}
