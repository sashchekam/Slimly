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
    /// Вес файла, который реально уйдёт в обработку.
    ///
    /// У медиа с правками медиатека хранит два файла: исходник с камеры и
    /// рендер обрезки. `byteCount` — исходник, как его показывает системная
    /// галерея, а обрабатываем мы рендер. Считать прогноз результата от
    /// исходника нельзя: минутное видео, обрезанное до тридцати секунд,
    /// дало бы вдвое завышенную оценку.
    public let sourceByteCount: Int64
    /// Только у видео.
    public let duration: Duration?
    /// HEIC можно переложить в JPEG — на вес это влияет слабо, на совместимость сильно.
    public let isHEIC: Bool
    /// Живое фото: у снимка есть короткий ролик, и в превью его можно
    /// проиграть. На обработку это не влияет — обрабатываем кадр.
    public let isLivePhoto: Bool
    /// Размер кадра: от него зависит, есть ли что уменьшать при сжатии,
    /// и он же подписывает превью в сравнении «до / после».
    public let pixelWidth: Int
    public let pixelHeight: Int
    /// Файл на диске, если элемент пришёл не из медиатеки: страница, снятая
    /// камерой, ассетом не является, и достать её по `id` неоткуда.
    public let sourceURL: URL?
    /// Когда снят файл. По ней подписана сетка выбора: в медиатеке файлы
    /// идут от свежих к старым, и дата — единственный ориентир при листании.
    /// У страницы, снятой камерой, её нет: медиатеке она не принадлежит.
    public let creationDate: Date?

    public init(
        id: String,
        kind: MediaKind,
        fileName: String,
        byteCount: Int64,
        sourceByteCount: Int64? = nil,
        duration: Duration? = nil,
        isHEIC: Bool = false,
        isLivePhoto: Bool = false,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        sourceURL: URL? = nil,
        creationDate: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.byteCount = byteCount
        self.sourceByteCount = sourceByteCount ?? byteCount
        self.duration = duration
        self.isHEIC = isHEIC
        self.isLivePhoto = isLivePhoto
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.sourceURL = sourceURL
        self.creationDate = creationDate
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
    var totalSourceByteCount: Int64 { reduce(0) { $0 + $1.sourceByteCount } }
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

/// Порция витрины: медиатеку читаем страницами, поэтому кроме файлов нужен
/// признак, осталось ли что грузить дальше. Считать его по длине страницы
/// нельзя: последняя порция может ровно совпасть с размером окна.
public struct MediaPage: Sendable, Hashable {
    public let items: [MediaItem]
    public let hasMore: Bool

    public init(items: [MediaItem], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }

    public static let empty = MediaPage(items: [], hasMore: false)
}

public extension Duration {
    /// Секунды дробным числом — для оценок веса и прогресса.
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}
