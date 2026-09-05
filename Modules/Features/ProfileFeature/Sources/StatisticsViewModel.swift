import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class StatisticsViewModel {
    /// Доля инструмента: кусок полосы и строка легенды под ней.
    public struct Share: Identifiable, Sendable {
        public let id: ProcessingKind
        public let label: String
        public let fraction: Double
        public let percentText: String
    }

    /// Пара «значение — подпись» в подвале карточки инструмента.
    public struct Fact: Identifiable, Sendable {
        public let id: String
        public let value: String
        public let label: String
    }

    /// Карточка инструмента целиком.
    public struct Card: Identifiable, Sendable {
        public let id: ProcessingKind
        public let title: String
        public let countText: String
        public let unit: String
        /// Одна фраза о том, что стоит за числом. Не пересказ цифры:
        /// цифра уже написана рядом крупно.
        public let note: String
        public let spark: [Double]
        public let facts: [Fact]
        /// Ведущий инструмент среза — он один красится акцентом.
        public let isLeading: Bool
    }

    public private(set) var range: StatsRange = .quarter
    public private(set) var history: ProcessingHistory = .empty
    /// Срез считается один раз на смену данных или периода, а не на каждое
    /// чтение: экран трогает его из десятка мест, а под ним лежит журнал
    /// на тысячу записей.
    public private(set) var digest = ProcessingHistory.empty.digest(for: .quarter)

    private let processingService: any MediaProcessingService
    private let analytics: ProfileAnalytics
    private let router: Router

    public init(
        processingService: any MediaProcessingService,
        analytics: ProfileAnalytics,
        router: Router
    ) {
        self.processingService = processingService
        self.analytics = analytics
        self.router = router
    }

    public func load() async {
        history = await processingService.history()
        digest = history.digest(for: range)
    }

    // MARK: Срез

    public var ranges: [StatsRange] { StatsRange.allCases }

    public func select(_ range: StatsRange) {
        guard range != self.range else { return }
        self.range = range
        digest = history.digest(for: range)
        analytics.didChangeRange(range)
    }

    public var periodText: String { digest.periodText() }

    public var isEmpty: Bool { digest.isEmpty }

    /// Что показать вместо цифр, пока их нет. Разные срезы пусты
    /// по разным причинам, и предлагать «сделайте что-нибудь» тому,
    /// кто просто выбрал прошлый месяц, не за что.
    public var emptyText: String {
        history.isEmpty
            ? L10n.Statistics.empty
            : L10n.Statistics.emptyPeriod
    }

    // MARK: Операции

    public var totalText: String { CountFormatter.string(digest.total) }

    public var shares: [Share] {
        digest.tools.map { tool in
            let fraction = digest.share(of: tool.kind)
            return Share(
                id: tool.kind,
                label: tool.kind.shortTitle,
                fraction: fraction,
                percentText: "\(Int((fraction * 100).rounded()))%"
            )
        }
    }

    // MARK: Карточки инструментов

    public var cards: [Card] {
        let peak = digest.tools.map(\.count).max() ?? 0

        return digest.tools.map { tool in
            Card(
                id: tool.kind,
                title: tool.kind.title,
                countText: CountFormatter.string(tool.count),
                unit: CountFormatter.word(tool.count, tool.kind.unit),
                note: note(for: tool),
                spark: tool.spark,
                facts: facts(for: tool),
                isLeading: tool.count > 0 && tool.count == peak
            )
        }
    }

    private func note(for tool: ToolStats) -> String {
        guard !tool.isEmpty else { return emptyNote(for: tool.kind) }

        switch tool.kind {
        case .compression:
            let saved = FileSizeFormatter.string(bytes: tool.savedByteCount)
            let gain = MediaItemFormatter.percent(tool.reduction)
            return L10n.Summary.compression(saved, gain)
        case .conversion:
            guard let top = tool.formatPairs.first else {
                return L10n.Summary.conversionUnknown
            }
            guard let second = tool.formatPairs.dropFirst().first else {
                return L10n.Summary.conversionSingle(top)
            }
            return L10n.Summary.conversionPair(top, second)
        case .audioExtraction:
            let format = tool.formats.first ?? "M4A"
            let total = DurationFormatter.total(seconds: tool.seconds)
            return L10n.Summary.audio(format, total)
        case .scan:
            let pages = CountFormatter.string(tool.pageCount, .page)
            let perDocument = CountFormatter.string(tool.pagesPerDocument, .page)
            return L10n.Summary.scan(pages, perDocument)
        }
    }

    private func emptyNote(for kind: ProcessingKind) -> String {
        switch kind {
        case .compression: L10n.Empty.compression
        case .conversion: L10n.Empty.conversion
        case .audioExtraction: L10n.Empty.audio
        case .scan: L10n.Empty.scan
        }
    }

    private func facts(for tool: ToolStats) -> [Fact] {
        switch tool.kind {
        case .compression:
            [
                fact(
                    "saved",
                    FileSizeFormatter.string(bytes: tool.savedByteCount),
                    L10n.Fact.freed
                ),
                fact(
                    "reduction",
                    MediaItemFormatter.percent(tool.reduction),
                    L10n.Fact.averageGain
                ),
            ]
        case .conversion:
            [
                fact("pair", tool.formatPairs.first, L10n.Fact.commonPair),
                fact("mix", mixText(for: tool), L10n.Fact.mix),
            ]
        case .audioExtraction:
            [
                fact(
                    "duration",
                    DurationFormatter.total(seconds: tool.seconds),
                    L10n.Fact.duration
                ),
                fact("format", tool.formats.first, L10n.Fact.mainFormat),
            ]
        case .scan:
            [
                fact(
                    "pages",
                    CountFormatter.string(tool.pageCount, .page),
                    L10n.Fact.captured
                ),
                fact("format", tool.formats.first ?? "PDF", L10n.Fact.format),
            ]
        }
    }

    /// «26 фото · 5 видео». Пустая половина выпадает: «0 видео» ничего
    /// не уточняет, а место занимает.
    private func mixText(for tool: ToolStats) -> String {
        var parts: [String] = []
        if tool.photoCount > 0 { parts.append(CountFormatter.string(tool.photoCount, .photo)) }
        if tool.videoCount > 0 { parts.append(CountFormatter.string(tool.videoCount, .video)) }
        return parts.joined(separator: " · ")
    }

    /// Прочерк вместо пустого значения: клетка без содержимого читается
    /// как сбой вёрстки, а прочерк — как честное «нечего показать».
    private func fact(_ id: String, _ value: String?, _ label: String) -> Fact {
        let value = value ?? ""
        return Fact(id: id, value: value.isEmpty ? "—" : value, label: label)
    }

    // MARK: Навигация

    public func goBack() {
        router.pop()
    }
}
