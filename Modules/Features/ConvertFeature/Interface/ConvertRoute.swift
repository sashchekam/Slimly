import SlimlyCore
import SlimlyNavigation

/// Что конвертируем. Экраны у фото и видео одни и те же, различаются
/// только выборка, форматы и подписи — поэтому это параметр маршрута,
/// а не отдельная фича.
public enum ConvertKind: String, Sendable, Hashable, CaseIterable {
    case photo
    case video
}

/// Публичный вход во флоу конвертации.
public enum ConvertRoute: Route {
    case picker(ConvertKind)
    case format(kind: ConvertKind, items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
}
