import SlimlyCore
import SlimlyNavigation

/// Публичный вход во флоу скана документа.
public enum ScanRoute: Route {
    /// Откуда берём страницы: камера или галерея.
    case intro
    /// Съёмка страниц. Показывается поверх флоу, а не в стеке: у камеры
    /// свой полноэкранный мир без шапки и полей.
    case camera
    case picker
    case format(items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
    /// Просмотр собранного документа с экрана итога.
    case preview(ProcessingResult)
}
