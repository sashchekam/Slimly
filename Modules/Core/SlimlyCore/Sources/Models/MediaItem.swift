import Foundation

public enum MediaKind: Sendable, Hashable {
    case photo
    case video
}

/// Файл медиатеки, отобранный для обработки.
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
    /// Размер кадра: от него зависит, есть ли что уменьшать при сжатии,
    /// и он же подписывает превью в сравнении «до / после».
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(
        id: String,
        kind: MediaKind,
        fileName: String,
        byteCount: Int64,
        duration: Duration? = nil,
        isHEIC: Bool = false,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.byteCount = byteCount
        self.duration = duration
        self.isHEIC = isHEIC
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    /// Имя без расширения — основа для имени результата.
    public var baseName: String {
        (fileName as NSString).deletingPathExtension
    }

    public var fileExtension: String {
        (fileName as NSString).pathExtension.lowercased()
    }

    /// «4032 × 3024». Пусто, если система размер не сообщила.
    public var pixelSizeText: String {
        guard pixelWidth > 0, pixelHeight > 0 else { return "" }
        return "\(pixelWidth) × \(pixelHeight)"
    }

    /// Длинная сторона кадра — по ней решаем, уменьшать ли изображение.
    public var longestSide: Int { max(pixelWidth, pixelHeight) }
}

public extension Sequence<MediaItem> {
    var totalByteCount: Int64 { reduce(0) { $0 + $1.byteCount } }
}

/// Альбом медиатеки.
///
/// «Недавние» — не настоящий альбом, а вся выборка целиком: так же, как
/// в системном пикере, это первый пункт списка, а не отдельный режим.
public struct MediaAlbum: Sendable, Hashable, Identifiable {
    public static let recentID = "recent"

    public let id: String
    public let title: String
    public let itemCount: Int

    public init(id: String, title: String, itemCount: Int) {
        self.id = id
        self.title = title
        self.itemCount = itemCount
    }

    public var isRecent: Bool { id == Self.recentID }
}

public extension Duration {
    /// Секунды дробным числом — для оценок веса и прогресса.
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}
