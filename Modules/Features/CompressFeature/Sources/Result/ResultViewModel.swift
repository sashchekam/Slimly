import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class ResultViewModel {
    public let outcome: CompressionOutcome

    private let router: Router
    /// Переход в соседний таб приходит замыканием: фича не знает ни про
    /// таб-бар, ни про то, как называется чужой таб.
    private let showProfile: @MainActor () -> Void

    public init(
        outcome: CompressionOutcome,
        router: Router,
        showProfile: @escaping @MainActor () -> Void
    ) {
        self.outcome = outcome
        self.router = router
        self.showProfile = showProfile
    }

    public var results: [CompressionResult] { outcome.results }

    public var beforeText: String {
        FileSizeFormatter.string(bytes: results.originalByteCount)
    }

    public var afterText: String {
        FileSizeFormatter.string(bytes: results.compressedByteCount)
    }

    public var summaryLine: String {
        var parts = [
            "Освободили \(FileSizeFormatter.string(bytes: results.savedByteCount))",
            CountFormatter.files(results.count),
        ]
        if outcome.options.keepsOriginals {
            parts.append("оригиналы на месте")
        }
        return parts.joined(separator: " · ")
    }

    public var unlockedAchievement: Achievement? {
        outcome.unlockedAchievements.first
    }

    public var deleteTitle: String {
        let size = FileSizeFormatter.string(bytes: results.originalByteCount)
        return "Удалить оригиналы — \(CountFormatter.files(results.count)), \(size)"
    }

    public var showsDeleteAction: Bool { outcome.options.keepsOriginals }

    // MARK: Действия

    public func finish() {
        router.popToRoot()
    }

    public func openProfile() {
        router.popToRoot()
        showProfile()
    }

    /// Удаление оригиналов — отдельный системный запрос, поэтому это шаг
    /// после результата, а не часть обработки. Настоящий
    /// `PHPhotoLibrary.performChanges` появится вместе с PhotoKit.
    public func deleteOriginals() {
        router.popToRoot()
    }
}
