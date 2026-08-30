import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class ProcessingViewModel {
    public let request: ProcessingRequest
    public private(set) var progress: ProcessingProgress

    private let service: any MediaProcessingService
    private let router: Router
    private let outcome: (ProcessingOutcome) -> any Route
    private let thumbnailLoader: MediaThumbnailLoader

    public init(
        request: ProcessingRequest,
        service: any MediaProcessingService,
        router: Router,
        thumbnails: @escaping MediaThumbnailLoader,
        outcome: @escaping (ProcessingOutcome) -> any Route
    ) {
        self.request = request
        self.service = service
        self.router = router
        thumbnailLoader = thumbnails
        self.outcome = outcome
        progress = .idle(request.items)
    }

    public var items: [MediaItem] { request.items }

    public var thumbnails: MediaThumbnailLoader { thumbnailLoader }

    /// Экран живёт ровно столько, сколько идёт поток: уход с экрана рвёт
    /// подписку, а вместе с ней — и саму обработку.
    public func run() async {
        for await event in service.process(request) {
            switch event {
            case let .progress(progress):
                self.progress = progress
            case let .finished(result):
                // Экран обработки из истории убираем: возврат с итога должен
                // вести на главную, а не запускать всё заново.
                router.setPath([outcome(result)])
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

    public var runWord: String { FlowCopy.runWord(request.kind) }

    /// Пока прогноз не на чем строить, так и пишем: выдуманные «40 с»
    /// на первых кадрах — обещание, которое некому сдержать.
    public var summaryLine: String {
        let count = CountFormatter.string(items.count, .file)
        guard let remaining = progress.estimatedRemaining else {
            return "Оцениваем время · \(count)"
        }
        return "Осталось \(DurationFormatter.remaining(remaining)) · \(count)"
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
