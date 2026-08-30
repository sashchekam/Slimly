import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class ProfileViewModel {
    public struct SettingsRow: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: String
    }

    public private(set) var snapshot: LibrarySnapshot?
    public private(set) var stats: ProcessingStats = .empty
    public private(set) var access: MediaAccess = .notDetermined

    private let mediaLibrary: any MediaLibrary
    private let processingService: any MediaProcessingService
    private let router: Router

    public init(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        router: Router
    ) {
        self.mediaLibrary = mediaLibrary
        self.processingService = processingService
        self.router = router
    }

    /// Доступ здесь только показываем: спрашивать его на экране статистики
    /// не за чем — системный запрос уместен там, где выбирают файлы.
    public func load() async {
        access = await mediaLibrary.access()
        async let snapshot = mediaLibrary.snapshot()
        async let stats = processingService.stats()

        self.snapshot = await snapshot
        self.stats = await stats
    }

    // MARK: Медиатека

    public var photoCountText: String {
        CountFormatter.string(snapshot?.photoCount ?? 0)
    }

    public var videoCountText: String {
        CountFormatter.string(snapshot?.videoCount ?? 0)
    }

    public var freeSpace: (value: String, unit: String) {
        FileSizeFormatter.parts(bytes: snapshot?.freeSpace ?? 0)
    }

    // MARK: Сжато нами

    public var savedText: String {
        FileSizeFormatter.string(bytes: stats.savedByteCount)
    }

    public var remainingFraction: Double { stats.remainingFraction }

    public var compressedText: String {
        "стало \(FileSizeFormatter.string(bytes: stats.compressedByteCount))"
    }

    public var originalText: String {
        "было \(FileSizeFormatter.string(bytes: stats.originalByteCount))"
    }

    public var breakdown: [(value: String, caption: String)] {
        [
            (CountFormatter.string(stats.photoCount), "фото"),
            (CountFormatter.string(stats.videoCount), "видео"),
            (
                CountFormatter.string(stats.conversionCount),
                CountFormatter.word(stats.conversionCount, .conversion)
            ),
        ]
    }

    // MARK: Настройки

    public var settingsRows: [SettingsRow] {
        [SettingsRow(id: "access", label: "Доступ к Фото", value: accessText)]
    }

    private var accessText: String {
        switch access {
        case .authorized: "Все фото"
        case .limited: "Выбранные фото"
        case .denied: "Запрещён"
        case .notDetermined: "Не запрошен"
        }
    }

    // MARK: Навигация

    public func goBack() {
        router.pop()
    }
}
