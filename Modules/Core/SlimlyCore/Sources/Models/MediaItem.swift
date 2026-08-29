import Foundation

public enum MediaKind: Sendable, Hashable {
    case photo
    case video
}

/// Файл медиатеки, отобранный для сжатия.
///
/// Размер храним в байтах: система отдаёт именно их, а мегабайты — уже
/// представление. `id` строковый, потому что в реальной медиатеке это
/// `localIdentifier` ассета, а не наш собственный ключ.
public struct MediaItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let kind: MediaKind
    public let fileName: String
    public let byteCount: Int64
    /// Только у видео.
    public let duration: Duration?
    /// HEIC можно переложить в JPEG — на вес это влияет слабо, на совместимость сильно.
    public let isHEIC: Bool

    public init(
        id: String,
        kind: MediaKind,
        fileName: String,
        byteCount: Int64,
        duration: Duration? = nil,
        isHEIC: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.byteCount = byteCount
        self.duration = duration
        self.isHEIC = isHEIC
    }
}

public extension Sequence<MediaItem> {
    var totalByteCount: Int64 { reduce(0) { $0 + $1.byteCount } }
}
