import SlimlyCore

/// Аналитика сжатия.
///
/// Шаги выбора, обработки и итога у сжатия общие с остальными инструментами
/// и пишутся в `flow_*`. Своё здесь одно — степень сжатия: это единственная
/// настройка, которую человек крутит руками, и по ней видно, чего от
/// приложения ждут — незаметной копии или самого лёгкого файла.
public struct CompressAnalytics: FeatureAnalytics {
    public static let scope = "compress"

    public let analytics: any AnalyticsService

    public init(analytics: any AnalyticsService) {
        self.analytics = analytics
    }

    /// Степень выбрана, сжатие запущено. Пресет — ближайшая засечка шкалы:
    /// ползунок непрерывный, и точное число в отчёте не с чем сравнивать.
    public func didPickLevel(_ level: CompressionLevel, request: ProcessingRequest) {
        track(
            "level_picked",
            [
                "preset": .text(level.nearestPreset.rawValue),
                "delta_percent": .int(request.deltaPercent),
            ]
        )
    }
}
