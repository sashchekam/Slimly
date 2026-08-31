import SlimlyCore
import SlimlyNavigation

/// Публичный вход во флоу извлечения звука.
public enum AudioRoute: Route {
    case picker
    case format(items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
    /// Прослушивание готовой дорожки с экрана итога.
    case preview(ProcessingResult)
}
