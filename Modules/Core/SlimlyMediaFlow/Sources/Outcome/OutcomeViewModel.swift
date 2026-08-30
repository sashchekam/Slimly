import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class OutcomeViewModel {
    public let outcome: ProcessingOutcome
    /// Что пошло не так при удалении оригиналов. Системный запрос можно
    /// и отклонить — тогда это не ошибка, но сказать об этом нужно.
    public private(set) var deletionMessage: String?
    public private(set) var isDeleting = false

    private let library: any MediaLibrary
    private let router: Router
    /// Сравнение «до / после» есть не у всех инструментов, поэтому маршрут
    /// приходит опциональным: нет маршрута — нет и строки-приглашения.
    private let comparison: ((ProcessingResult) -> any Route)?

    public init(
        outcome: ProcessingOutcome,
        library: any MediaLibrary,
        router: Router,
        comparison: ((ProcessingResult) -> any Route)? = nil
    ) {
        self.outcome = outcome
        self.library = library
        self.router = router
        self.comparison = comparison
    }

    public var results: [ProcessingResult] { outcome.results }

    public var failures: [ProcessingFailure] { outcome.failures }

    public var thumbnails: MediaThumbnailLoader { library.thumbnailLoader }

    // MARK: Заголовок

    public var kicker: String {
        outcome.isEmpty ? "ничего не вышло" : FlowCopy.doneKicker(outcome.kind)
    }

    /// У сжатия итог — это вес, у остальных — формат: показываем ту пару,
    /// ради которой всё затевалось.
    public var showsSizeHeadline: Bool { outcome.kind == .compression }

    public var beforeText: String {
        FileSizeFormatter.string(bytes: results.originalByteCount)
    }

    public var afterText: String {
        FileSizeFormatter.string(bytes: results.outputByteCount)
    }

    public var sourceFormat: String { outcome.request.sourceFormat }

    public var targetFormat: String { outcome.request.targetFormat?.id ?? "" }

    public var summary: String {
        guard !outcome.isEmpty else {
            return "Ни один файл обработать не удалось — подробности ниже."
        }
        return FlowCopy.summary(outcome)
    }

    /// Куда всё уехало. Медиатеку не поясняем — там результат и ищут,
    /// а вот дорожку в «Файлах» без подсказки не найти.
    public var destinationNote: String? {
        guard results.contains(where: { $0.destination == .files }) else { return nil }
        return "Файлы приложения → Slimly. Откройте «Файлы» → «На iPhone» → Slimly."
    }

    public var failureSummary: String? {
        guard !failures.isEmpty else { return nil }
        return "Не удалось обработать: \(CountFormatter.string(failures.count, .file))"
    }

    // MARK: Список файлов

    public func name(for result: ProcessingResult) -> String { result.outputName }

    public func detail(for result: ProcessingResult) -> String {
        switch outcome.kind {
        case .compression:
            MediaItemFormatter.sizeTransition(
                from: result.item.byteCount,
                to: result.outputByteCount
            )
        case .audioExtraction:
            "дорожка \(FileSizeFormatter.string(bytes: result.outputByteCount))"
        case .conversion, .scan:
            "\(sourceFormat) → \(outcome.request.targetFormat?.shortName ?? "")"
        }
    }

    public func delta(for result: ProcessingResult) -> String {
        outcome.kind == .compression
            ? MediaItemFormatter.reduction(result)
            : (outcome.request.targetFormat?.shortName ?? "")
    }

    public var allowsComparison: Bool { comparison != nil }

    public func canCompare(_ result: ProcessingResult) -> Bool {
        allowsComparison && result.outputURL != nil
    }

    // MARK: Удаление оригиналов

    public var showsDeleteOriginals: Bool {
        FlowCopy.offersDeletingOriginals(outcome.kind) && !outcome.isEmpty
    }

    public var deleteSubtitle: String {
        let size = FileSizeFormatter.string(bytes: results.originalByteCount)
        return "\(CountFormatter.string(results.count, .file)), \(size) · iOS покажет свой запрос"
    }

    // MARK: Действия

    public func finish() {
        router.popToRoot()
    }

    public func openComparison(_ result: ProcessingResult) {
        guard let comparison, canCompare(result) else { return }
        router.push(comparison(result))
    }

    /// Удаление — отдельный шаг после итога, а не часть обработки:
    /// подтверждение показывает система, и до её запроса оригиналы должны
    /// быть уже заменены готовыми файлами.
    public func deleteOriginals() {
        guard !isDeleting else { return }
        isDeleting = true
        deletionMessage = nil

        Task {
            do {
                try await library.deleteOriginals(results.map(\.item))
                isDeleting = false
                router.popToRoot()
            } catch {
                isDeleting = false
                deletionMessage = "Оригиналы остались на месте"
            }
        }
    }
}
