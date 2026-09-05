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
            case language
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
    /// Язык интерфейса — прямо из сервиса: он наблюдаемый, и строка меняется
    /// вместе с выбором на соседнем экране.
    public var language: AppLanguage { localization.current }
    public private(set) var toast: String?

    private let mediaLibrary: any MediaLibrary
    private let processingService: any MediaProcessingService
    private let localization: any LocalizationService
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
        localization: any LocalizationService,
        analytics: ProfileAnalytics,
        environment: AppEnvironment = .current,
        debugMenu: (any Route)? = nil,
        router: Router
    ) {
        self.mediaLibrary = mediaLibrary
        self.processingService = processingService
        self.localization = localization
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
        let size = FileSizeFormatter.string(bytes: stats.compressedByteCount)
        return L10n.Profile.now(size)
    }

    public var originalText: String {
        let size = FileSizeFormatter.string(bytes: stats.originalByteCount)
        return L10n.Profile.was(size)
    }

    public var breakdown: [(value: String, caption: String)] {
        [
            (CountFormatter.string(stats.photoCount), L10n.Unit.photos),
            (CountFormatter.string(stats.videoCount), L10n.Unit.videos),
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

    public var usageCaption: String {
        L10n.Profile.over(Self.usageRange.title)
    }

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
            SettingsRow(
                id: .language,
                label: L10n.Language.title,
                value: language.nativeName,
                isTappable: true
            ),
            SettingsRow(
                id: .access,
                label: L10n.Profile.photosAccess,
                value: accessText,
                isTappable: false
            ),
            SettingsRow(
                id: .version,
                label: L10n.Profile.version,
                value: environment.versionText,
                isTappable: debugMenu != nil
            ),
        ]
    }

    private var accessText: String {
        switch access {
        case .authorized: L10n.Permission.authorized
        case .limited: L10n.Permission.limited
        case .denied: L10n.Permission.denied
        case .notDetermined: L10n.Permission.notDetermined
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
        if row.id == .language {
            router.push(ProfileRoute.language)
            return
        }

        guard row.id == .version, let debugMenu else { return }

        versionTaps += 1
        switch versionTaps {
        case 5...:
            versionTaps = 0
            router.cover(debugMenu)
        case 3, 4:
            say(L10n.Profile.debugCountdown(5 - versionTaps))
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
