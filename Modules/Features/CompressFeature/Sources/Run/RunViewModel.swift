import Foundation
import Observation
import CompressFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class RunViewModel {
    public let items: [MediaItem]
    public private(set) var progress: CompressionProgress

    private let options: CompressionOptions
    private let compressionService: any CompressionService
    private let router: Router

    public init(
        items: [MediaItem],
        options: CompressionOptions,
        compressionService: any CompressionService,
        router: Router
    ) {
        self.items = items
        self.options = options
        self.compressionService = compressionService
        self.router = router
        progress = CompressionProgress(
            overall: 0,
            items: items.map { ItemProgress(id: $0.id, fraction: 0) },
            estimatedRemaining: .seconds(40)
        )
    }

    /// Экран живёт ровно столько, сколько идёт поток: уход с экрана рвёт
    /// подписку, а вместе с ней — и саму обработку.
    public func run() async {
        for await event in compressionService.compress(items, options: options) {
            switch event {
            case let .progress(progress):
                self.progress = progress
            case let .finished(outcome):
                // Экран обработки из истории убираем: возврат с результата
                // должен вести к выбору файлов, а не запускать всё заново.
                router.setPath([CompressRoute.result(outcome)])
            }
        }
    }

    public func cancel() {
        router.popToRoot()
    }

    // MARK: Показатели

    public var percentText: String {
        "\(Int((progress.overall * 100).rounded()))%"
    }

    public var summaryLine: String {
        let remaining = DurationFormatter.remaining(progress.estimatedRemaining)
        return "Осталось \(remaining) · \(CountFormatter.files(items.count))"
    }

    public func fraction(for item: MediaItem) -> Double {
        progress.fraction(for: item)
    }

    public func state(for item: MediaItem) -> String {
        let fraction = progress.fraction(for: item)
        if fraction >= 1 { return "готово" }
        if fraction <= 0 { return "ждёт" }
        return "\(Int((fraction * 100).rounded()))%"
    }
}
