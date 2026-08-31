import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Правила шага выбора файлов для конкретного инструмента.
public struct MediaPickerConfig: Sendable {
    public let title: String
    public let hint: String
    /// Чем ограничена выборка: конвертеру видео нечего показывать фото.
    public let kind: MediaKind?
    /// Сколько файлов можно взять за раз — предел бесплатной обработки.
    public let limit: Int
    public let noun: CountFormatter.Noun
    /// Показывать ли вес файлов. У скана он ни на что не влияет: страницу
    /// выбирают по содержимому, а не по мегабайтам.
    public let showsSize: Bool

    public init(
        title: String,
        hint: String,
        kind: MediaKind?,
        limit: Int,
        noun: CountFormatter.Noun,
        showsSize: Bool = true
    ) {
        self.title = title
        self.hint = hint
        self.kind = kind
        self.limit = limit
        self.noun = noun
        self.showsSize = showsSize
    }
}

@MainActor
@Observable
public final class MediaPickerViewModel {
    public let config: MediaPickerConfig

    public private(set) var albums: [MediaAlbum] = []
    public private(set) var items: [MediaItem] = []
    /// Выбор в порядке нажатий: у скана этот порядок становится порядком
    /// страниц, поэтому множеством его хранить нельзя.
    public private(set) var selection: [MediaItem] = []
    public private(set) var albumID = MediaAlbum.recentID
    public private(set) var access: MediaAccess = .notDetermined
    public private(set) var isLoading = true

    private let library: any MediaLibrary
    private let router: Router
    private let destination: ([MediaItem]) -> FlowDestination

    public init(
        config: MediaPickerConfig,
        library: any MediaLibrary,
        router: Router,
        destination: @escaping ([MediaItem]) -> FlowDestination
    ) {
        self.config = config
        self.library = library
        self.router = router
        self.destination = destination
    }

    public var thumbnails: MediaThumbnailLoader { library.thumbnailLoader }

    // MARK: Загрузка

    /// Системный запрос доступа показываем не на главной, а здесь: спрашивать
    /// про Фото имеет смысл в тот момент, когда пользователь пришёл выбирать
    /// файлы, — тогда понятно, зачем.
    public func load() async {
        if !access.allowsBrowsing {
            access = await library.access()
            if access == .notDetermined {
                access = await library.requestAccess()
            }
        }

        guard access.allowsBrowsing else {
            isLoading = false
            return
        }

        async let albums = library.albums(kind: config.kind)
        async let items = library.items(in: albumID, kind: config.kind)

        self.albums = await albums
        self.items = await items
        isLoading = false
    }

    public func select(_ album: MediaAlbum) {
        guard album.id != albumID else { return }
        albumID = album.id
        isLoading = true
        // Выбор не сбрасываем: альбом — это фильтр витрины, а не новая сессия.
        Task {
            items = await library.items(in: album.id, kind: config.kind)
            // Пока читался альбом, пользователь мог переключиться на другой:
            // тогда индикатор снимает уже та, более поздняя загрузка.
            guard albumID == album.id else { return }
            isLoading = false
        }
    }

    public var currentAlbum: MediaAlbum? {
        albums.first { $0.id == albumID }
    }

    // MARK: Состояние экрана

    public var isDenied: Bool { access == .denied }

    /// Доступ есть, а показывать нечего: у инструмента своя выборка,
    /// и в медиатеке может просто не быть видео.
    public var isEmpty: Bool {
        !isLoading && access.allowsBrowsing && items.isEmpty
    }

    public var emptyTitle: String {
        switch config.kind {
        case .video: "Видео не найдено"
        case .photo: "Фото не найдено"
        case nil: "Медиатека пуста"
        }
    }

    /// При частичном доступе список — это ровно то, что пользователь отобрал
    /// сам, поэтому «пусто» здесь значит другое, и подсказка тоже.
    public var emptyHint: String {
        access == .limited
            ? "Приложению открыта только часть медиатеки. Добавьте файлы в системном списке."
            : "В выбранном альбоме нечего обрабатывать."
    }

    public var showsLimitedNotice: Bool {
        access == .limited && !items.isEmpty
    }

    // MARK: Выбор

    public func isSelected(_ item: MediaItem) -> Bool {
        selection.contains { $0.id == item.id }
    }

    /// Плитка сверх лимита не гаснет молча: она приглушена и не реагирует,
    /// поэтому предел виден до нажатия, а не после отказа.
    public func isBlocked(_ item: MediaItem) -> Bool {
        !isSelected(item) && isAtLimit
    }

    public func toggle(_ item: MediaItem) {
        if let index = selection.firstIndex(where: { $0.id == item.id }) {
            selection.remove(at: index)
        } else if !isAtLimit {
            selection.append(item)
        }
    }

    public var isAtLimit: Bool { selection.count >= config.limit }

    public var hasSelection: Bool { !selection.isEmpty }

    // MARK: Показатели

    public var limitTitle: String { "\(selection.count) из \(config.limit)" }

    public var limitFraction: Double {
        min(Double(selection.count) / Double(config.limit), 1)
    }

    public var ctaTitle: String {
        let count = CountFormatter.string(selection.count, config.noun)
        guard config.showsSize else { return "Далее · \(count)" }
        return "Далее · \(count) · \(FileSizeFormatter.string(bytes: selection.totalByteCount))"
    }

    // MARK: Навигация

    public func goBack() {
        router.pop()
    }

    public func proceed() {
        guard hasSelection else { return }

        switch destination(selection) {
        case let .push(route): router.push(route)
        case let .present(route): router.present(route)
        case let .cover(route): router.cover(route)
        }
    }
}
