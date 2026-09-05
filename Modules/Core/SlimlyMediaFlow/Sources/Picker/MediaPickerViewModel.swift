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
    /// Догрузка следующей страницы: сетка уже видна, поэтому индикатор
    /// у неё свой, под последним рядом.
    public private(set) var isLoadingMore = false

    /// Сколько файлов читаем за раз. Вес каждого система отдаёт поштучно,
    /// поэтому окно небольшое: экран открывается сразу, а остальное
    /// подтягивается по мере прокрутки.
    private static let pageSize = 150
    /// За сколько плиток до конца просим следующую страницу. Пары рядов
    /// запаса хватает, чтобы догрузка прошла до того, как список кончится.
    private static let prefetchDistance = 24

    /// Есть ли что грузить дальше — по этому признаку сетка держит внизу
    /// подвал, который и просит следующую страницу.
    public private(set) var hasMore = false
    /// Плитка, на которой пора просить продолжение. Хранится идентификатором,
    /// а не индексом: искать позицию при каждом появлении плитки — обход
    /// списка, который к концу медиатеки станет длинным.
    private var prefetchTriggerID: String?
    /// Докуда дочитали. Считается страницами, а не длиной витрины: повторы
    /// из неё выбрасываются, и по ней окно бы не двигалось.
    private var offset = 0
    private var shownIDs: Set<String> = []
    private var pageTask: Task<Void, Never>?

    private let library: any MediaLibrary
    private let analytics: FlowAnalytics
    private let router: Router
    private let destination: ([MediaItem]) -> FlowDestination

    public init(
        config: MediaPickerConfig,
        library: any MediaLibrary,
        analytics: FlowAnalytics,
        router: Router,
        destination: @escaping ([MediaItem]) -> FlowDestination
    ) {
        self.config = config
        self.library = library
        self.analytics = analytics
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
            // Событие шлём только после настоящего системного запроса:
            // на втором заходе диалога уже нет, и «ответ» был бы выдумкой.
            if access == .notDetermined {
                access = await library.requestAccess()
                analytics.didAnswerAccess(access)
            }
            analytics.setAccess(access)
        }

        guard access.allowsBrowsing else {
            isLoading = false
            return
        }

        async let albums = library.albums(kind: config.kind)
        async let page = library.items(in: albumID, kind: config.kind, offset: 0, limit: Self.pageSize)

        self.albums = await albums
        apply(await page)
        isLoading = false
    }

    public func select(_ album: MediaAlbum) {
        guard album.id != albumID else { return }
        albumID = album.id
        isLoading = true
        // Выбор не сбрасываем: альбом — это фильтр витрины, а не новая сессия.
        reset()

        pageTask = Task {
            let page = await library.items(in: album.id, kind: config.kind, offset: 0, limit: Self.pageSize)
            // Пока читался альбом, пользователь мог переключиться на другой:
            // тогда витрину заполняет уже та, более поздняя загрузка.
            guard !Task.isCancelled, albumID == album.id else { return }
            apply(page)
            isLoading = false
        }
    }

    /// Сетка сообщает, какая плитка появилась в списке. Продолжение просим
    /// не по кнопке и не в самом низу: пользователь листает медиатеку
    /// непрерывно, и пауза посреди прокрутки читалась бы как конец списка.
    public func willShow(_ item: MediaItem) {
        guard item.id == prefetchTriggerID else { return }
        loadMoreIfNeeded()
    }

    /// Страховка на быструю прокрутку: подвал сетки просит продолжение сам,
    /// если плитку-триггер список успел проскочить.
    public func loadMoreIfNeeded() {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        prefetchTriggerID = nil

        let album = albumID
        let start = offset
        pageTask = Task {
            let page = await library.items(in: album, kind: config.kind, offset: start, limit: Self.pageSize)
            guard !Task.isCancelled, albumID == album else { return }
            apply(page, appending: true)
            isLoadingMore = false
        }
    }

    private func apply(_ page: MediaPage, appending: Bool = false) {
        if !appending {
            shownIDs.removeAll()
            offset = 0
        }
        // Медиатека могла измениться между страницами — тогда окно сдвинется
        // и файл придёт вторым экземпляром. Для `ForEach` это одинаковые
        // идентификаторы, поэтому повторы отсекаем здесь.
        let fresh = page.items.filter { shownIDs.insert($0.id).inserted }
        items = appending ? items + fresh : fresh
        offset += page.items.count
        hasMore = page.hasMore
        // Когда до конца ближе запаса, ждать нечего: следующую страницу
        // просит первая же плитка, которая появится.
        let trigger = max(items.count - Self.prefetchDistance, 0)
        prefetchTriggerID = hasMore && trigger < items.count ? items[trigger].id : nil
    }

    private func reset() {
        pageTask?.cancel()
        pageTask = nil
        items = []
        shownIDs = []
        offset = 0
        hasMore = false
        prefetchTriggerID = nil
        isLoadingMore = false
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
        case .video: L10n.Picker.emptyVideos
        case .photo: L10n.Picker.emptyPhotos
        case nil: L10n.Picker.emptyLibrary
        }
    }

    /// При частичном доступе список — это ровно то, что пользователь отобрал
    /// сам, поэтому «пусто» здесь значит другое, и подсказка тоже.
    public var emptyHint: String {
        access == .limited
            ? L10n.Picker.emptyLimited
            : L10n.Picker.emptyAlbum
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

    public var limitTitle: String {
        L10n.Picker.counter(selection.count, config.limit)
    }

    public var limitFraction: Double {
        min(Double(selection.count) / Double(config.limit), 1)
    }

    public var ctaTitle: String {
        let count = CountFormatter.string(selection.count, config.noun)
        guard config.showsSize else { return L10n.Picker.action(count) }
        let size = FileSizeFormatter.string(bytes: selection.totalByteCount)
        return L10n.Picker.actionWithSize(count, size)
    }

    // MARK: Навигация

    public func goBack() {
        router.pop()
    }

    public func proceed() {
        guard hasSelection else { return }

        analytics.didPickFiles(selection)
        router.go(to: destination(selection))
    }
}
