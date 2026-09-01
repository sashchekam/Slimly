import SlimlyCore
import SlimlyNavigation

/// Публичный вход во флоу извлечения звука.
public enum AudioRoute: Route {
    case picker
    case format(items: [MediaItem])
    /// Просмотр исходного видео с шага выбора формата дорожки.
    case sourcePreview(MediaItem)
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
    /// Прослушивание готовой дорожки: шторка поверх экрана итога.
    case preview(ProcessingResult)
}
