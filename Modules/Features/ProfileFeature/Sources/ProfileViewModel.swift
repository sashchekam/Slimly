import Foundation
import Observation
import SlimlyCore

@MainActor
@Observable
public final class ProfileViewModel {
    public struct SettingsRow: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: String
    }

    public private(set) var snapshot: LibrarySnapshot?
    public private(set) var stats: CompressionStats = .empty

    private let mediaLibrary: any MediaLibrary
    private let compressionService: any CompressionService

    public init(mediaLibrary: any MediaLibrary, compressionService: any CompressionService) {
        self.mediaLibrary = mediaLibrary
        self.compressionService = compressionService
    }

    public func load() async {
        async let snapshot = mediaLibrary.snapshot()
        async let stats = compressionService.stats()

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

    // MARK: Ачивки

    public var achievements: [Achievement] { Achievement.catalogue }

    public func isEarned(_ achievement: Achievement) -> Bool {
        achievement.isEarned(in: stats)
    }

    public var earnedCountText: String {
        "\(Achievement.earned(in: stats).count) из \(Achievement.catalogue.count)"
    }

    public var nextAchievement: Achievement? {
        Achievement.next(in: stats)
    }

    public func progress(for achievement: Achievement) -> Double {
        achievement.progress(in: stats)
    }

    public func progressText(for achievement: Achievement) -> String {
        achievement.progressText(in: stats)
    }

    // MARK: Настройки

    public var settingsRows: [SettingsRow] {
        [
            SettingsRow(
                id: "preset",
                label: "Пресет по умолчанию",
                value: CompressionOptions.default.preset.title
            ),
            // Реальный статус придёт из PhotoKit вместе с настоящей медиатекой.
            SettingsRow(id: "access", label: "Доступ к Фото", value: "Все фото"),
            SettingsRow(
                id: "history",
                label: "История сжатий",
                value: CountFormatter.string(stats.fileCount)
            ),
            SettingsRow(id: "about", label: "О приложении", value: Self.appVersion),
        ]
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
