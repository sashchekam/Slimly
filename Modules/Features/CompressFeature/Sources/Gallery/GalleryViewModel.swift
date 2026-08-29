import Foundation
import Observation
import CompressFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class GalleryViewModel {
    public private(set) var snapshot: LibrarySnapshot?
    public private(set) var stats: CompressionStats = .empty
    public private(set) var items: [MediaItem] = []
    public private(set) var recent: [CompressionResult] = []

    /// Выбор пользователя. Пустой на старте: подставлять чужие файлы
    /// в выделение нельзя, даже ради красивого первого экрана.
    public private(set) var selectedIDs: Set<String> = []

    private let mediaLibrary: any MediaLibrary
    private let compressionService: any CompressionService
    private let router: Router

    public init(
        mediaLibrary: any MediaLibrary,
        compressionService: any CompressionService,
        router: Router
    ) {
        self.mediaLibrary = mediaLibrary
        self.compressionService = compressionService
        self.router = router
    }

    // MARK: Загрузка

    public func load() async {
        async let snapshot = mediaLibrary.snapshot()
        async let items = mediaLibrary.recentItems(limit: 9)
        async let stats = compressionService.stats()
        async let recent = compressionService.recentResults(limit: 3)

        self.snapshot = await snapshot
        self.items = await items
        self.stats = await stats
        self.recent = await recent

        // Файл мог исчезнуть из медиатеки между заходами на экран.
        selectedIDs.formIntersection(Set(self.items.map(\.id)))
    }

    /// Системный выбор файлов. Пока медиатека — заглушка, открывать нечего,
    /// поэтому просто перечитываем список; настоящий `PhotosPicker` появится
    /// вместе с реализацией ``MediaLibrary`` поверх PhotoKit.
    public func openPicker() async {
        await load()
    }

    // MARK: Выбор

    public func isSelected(_ item: MediaItem) -> Bool {
        selectedIDs.contains(item.id)
    }

    public func toggle(_ item: MediaItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    public var selectedItems: [MediaItem] {
        items.filter { selectedIDs.contains($0.id) }
    }

    public var hasSelection: Bool { !selectedIDs.isEmpty }

    // MARK: Показатели

    public var freeSpaceText: String {
        guard let snapshot else { return "—" }
        return FileSizeFormatter.string(bytes: snapshot.freeSpace)
    }

    public var savedText: String {
        FileSizeFormatter.string(bytes: stats.savedByteCount)
    }

    public var savedSubtitle: String {
        "за \(CountFormatter.files(stats.fileCount))"
    }

    public var savedTransition: String {
        let before = FileSizeFormatter.string(bytes: stats.originalByteCount)
        let after = FileSizeFormatter.string(bytes: stats.compressedByteCount)
        return "\(before) было → \(after) стало"
    }

    public var ctaTitle: String {
        let items = selectedItems
        let size = FileSizeFormatter.string(bytes: items.totalByteCount)
        return "Далее · \(CountFormatter.files(items.count)) · \(size)"
    }

    // MARK: Навигация

    public func openSetup() {
        guard hasSelection else { return }
        router.push(CompressRoute.setup(items: selectedItems, options: .default))
    }

    /// Плитка «HEIC → JPEG» — тот же экран настроек, но с заранее включённой
    /// конвертацией: пользователь пришёл именно за ней.
    ///
    /// Это ещё и быстрый путь: если ничего не выбрано, берём все HEIC
    /// из списка — иначе кнопка требовала бы сначала повторить выбор руками.
    public func openHEICConversion() {
        let target = hasSelection ? selectedItems : items.filter(\.isHEIC)
        guard !target.isEmpty else { return }

        var options = CompressionOptions.default
        options.convertsHEICToJPEG = true
        router.push(CompressRoute.setup(items: target, options: options))
    }

    public var hasHEICShortcut: Bool {
        hasSelection || items.contains(where: \.isHEIC)
    }
}
