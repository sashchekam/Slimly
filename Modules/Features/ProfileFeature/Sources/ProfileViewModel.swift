import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class ProfileViewModel {
    public struct SettingsRow: Identifiable, Sendable {
        public enum ID: String, Sendable {
            case access
            case version
        }

        public let id: ID
        public let label: String
        public let value: String
        /// Строка без действия — просто показание: у неё нет ни нажатия,
        /// ни шеврона, обещающего продолжение.
        public let isTappable: Bool
    }

    public private(set) var snapshot: LibrarySnapshot?
    public private(set) var stats: ProcessingStats = .empty
    public private(set) var access: MediaAccess = .notDetermined
    public private(set) var toast: String?

    private let mediaLibrary: any MediaLibrary
    private let processingService: any MediaProcessingService
    private let environment: AppEnvironment
    /// Маршрут отладочного меню. В релизной сборке его нет — и строка версии
    /// остаётся обычным показанием, а не спрятанной дверью.
    private let debugMenu: (any Route)?
    private let router: Router

    private var versionTaps = 0

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    public init(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        environment: AppEnvironment = .current,
        debugMenu: (any Route)? = nil,
        router: Router
    ) {
        self.mediaLibrary = mediaLibrary
        self.processingService = processingService
        self.environment = environment
        self.debugMenu = debugMenu
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
        [
            SettingsRow(id: .access, label: "Доступ к Фото", value: accessText, isTappable: false),
            SettingsRow(
                id: .version,
                label: "Версия",
                value: environment.versionText,
                isTappable: debugMenu != nil
            ),
        ]
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

    /// Пять нажатий на версию открывают отладочное меню.
    ///
    /// Второй вход рядом с тряской нужен потому, что трясти телефон в чужих
    /// руках — так себе инструкция: по телефону проще сказать «нажмите
    /// пять раз на версию».
    public func tap(_ row: SettingsRow) {
        guard row.id == .version, let debugMenu else { return }

        versionTaps += 1
        switch versionTaps {
        case 5...:
            versionTaps = 0
            router.cover(debugMenu)
        case 3, 4:
            say("Ещё \(5 - versionTaps) — и откроется Debug-меню")
        default:
            break
        }
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
