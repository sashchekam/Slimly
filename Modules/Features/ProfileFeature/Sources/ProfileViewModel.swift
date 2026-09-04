import Foundation
import Observation
import ProfileFeatureInterface
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

    /// Плитка инструмента в карточке «чем вы пользовались».
    public struct UsageTile: Identifiable, Sendable {
        public let id: ProcessingKind
        public let title: String
        public let countText: String
        public let unit: String
        /// Длина полоски — доля от самого частого инструмента, а не от всех
        /// операций: полоски здесь сравнивают инструменты между собой.
        public let share: Double
        /// Самый частый инструмент подсвечен акцентом: подсветить все —
        /// значит не подсветить ни одного.
        public let isLeading: Bool
    }

    public private(set) var snapshot: LibrarySnapshot?
    public private(set) var stats: ProcessingStats = .empty
    /// Срез журнала для карточки «чем вы пользовались». Считается один раз
    /// при загрузке: под ним лежит журнал на тысячу записей, а экран читает
    /// плитки на каждой перерисовке.
    public private(set) var usageDigest = ProcessingHistory.empty.digest(for: ProfileViewModel.usageRange)
    public private(set) var access: MediaAccess = .notDetermined
    public private(set) var toast: String?

    private let mediaLibrary: any MediaLibrary
    private let processingService: any MediaProcessingService
    private let analytics: ProfileAnalytics
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
        analytics: ProfileAnalytics,
        environment: AppEnvironment = .current,
        debugMenu: (any Route)? = nil,
        router: Router
    ) {
        self.mediaLibrary = mediaLibrary
        self.processingService = processingService
        self.analytics = analytics
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
        async let history = processingService.history()

        self.snapshot = await snapshot
        self.stats = await stats
        usageDigest = await history.digest(for: Self.usageRange)
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

    // MARK: Чем пользовались

    /// Срез для карточки в профиле фиксирован: она отвечает на «чем я
    /// пользуюсь сейчас», а выбор глубины живёт на экране статистики,
    /// куда карточка и ведёт.
    public static let usageRange: StatsRange = .quarter

    public var usageCaption: String { "за \(Self.usageRange.title)" }

    public var usage: [UsageTile] {
        let peak = usageDigest.tools.map(\.count).max() ?? 0

        return usageDigest.tools.map { tool in
            UsageTile(
                id: tool.kind,
                title: tool.kind.title,
                countText: CountFormatter.string(tool.count),
                unit: CountFormatter.word(tool.count, tool.kind.unit),
                share: peak > 0 ? Double(tool.count) / Double(peak) : 0,
                isLeading: tool.count > 0 && tool.count == peak
            )
        }
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

    /// Плитка и ссылка ведут на один экран: плитка — не фильтр, а тот же
    /// вопрос, заданный с конкретного инструмента в руках.
    public func openStatistics(from source: StatisticsSource) {
        analytics.didOpenStatistics(from: source)
        router.push(ProfileRoute.statistics)
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
