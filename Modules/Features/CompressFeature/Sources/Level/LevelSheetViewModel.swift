import Foundation
import Observation
import CompressFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class LevelSheetViewModel {
    public let items: [MediaItem]
    public var level: CompressionLevel = .default

    private let router: Router

    public init(items: [MediaItem], router: Router) {
        self.items = items
        self.router = router
    }

    public var presets: [CompressionPreset] { CompressionPreset.allCases }

    public func isNearest(_ preset: CompressionPreset) -> Bool {
        level.nearestPreset == preset
    }

    /// Тап по подписи пресета ставит ползунок на его засечку — подпись
    /// работает как кнопка, но шкала остаётся непрерывной.
    public func select(_ preset: CompressionPreset) {
        level = .at(preset)
    }

    public var presetSummary: String { level.nearestPreset.summary }

    // MARK: Показатели

    private var request: ProcessingRequest {
        ProcessingRequest(items: items, operation: .compress(level))
    }

    public var deltaText: String { "−\(request.deltaPercent)%" }

    public var beforeText: String {
        FileSizeFormatter.string(bytes: request.originalByteCount)
    }

    public var afterText: String {
        FileSizeFormatter.string(bytes: request.estimatedByteCount)
    }

    public var savedText: String {
        FileSizeFormatter.string(bytes: max(0, request.originalByteCount - request.estimatedByteCount))
    }

    public var remainingFraction: Double { min(level.ratio, 1) }

    public var selectionText: String {
        let size = FileSizeFormatter.string(bytes: request.originalByteCount)
        return "\(CountFormatter.string(items.count, .file)), \(size)"
    }

    public var ctaTitle: String { "Сжать · \(selectionText)" }

    // MARK: Навигация

    public func cancel() {
        router.dismiss()
    }

    /// Обработка идёт в стеке под шторкой: шторка закрывается, а экран
    /// обработки встаёт поверх выбора файлов, а не внутри модалки.
    public func start() {
        let parent = router.parent ?? router
        router.dismiss()
        parent.push(CompressRoute.run(request))
    }
}
