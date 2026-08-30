import SlimlyCore
import SlimlyNavigation

/// Публичный вход во флоу скана документа.
public enum ScanRoute: Route {
    /// Откуда берём страницы: камера или галерея.
    case intro
    case picker
    case format(items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
}
