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
    private let analytics: FlowAnalytics
    private let router: Router
    private let outcome: (ProcessingOutcome) -> any Route
    private let thumbnailLoader: MediaThumbnailLoader

    public init(
        request: ProcessingRequest,
        service: any MediaProcessingService,
        analytics: FlowAnalytics,
        router: Router,
        thumbnails: @escaping MediaThumbnailLoader,
        outcome: @escaping (ProcessingOutcome) -> any Route
    ) {
        self.request = request
        self.service = service
        self.analytics = analytics
        self.router = router
        thumbnailLoader = thumbnails
        self.outcome = outcome
        progress = .idle(request.items)
    }

    public var items: [MediaItem] { request.items }

    public var thumbnails: MediaThumbnailLoader { thumbnailLoader }

    /// Пара небольших файлов обрабатывается за доли секунды — быстрее, чем
    /// кольцо успевает проехать хотя бы четверть круга. Экран в таком случае
    /// мелькает, а анимации обрываются на полпути, поэтому прогресс показываем
    /// не быстрее темпа «полный круг за это время».
    private static let minimumRun: Duration = .seconds(2)

    /// Экран живёт ровно столько, сколько идёт поток: уход с экрана рвёт
    /// подписку, а вместе с ней — и саму обработку.
    public func run() async {
        let clock = ContinuousClock()
        let start = clock.now
        // Старт пишем здесь, а не на кнопке предыдущего шага: у сжатия
        // её нажимают в шторке, и точка запуска у инструментов разъехалась
        // бы, хотя работа начинается в одном и том же месте.
        analytics.didStartRun(request)

        for await event in service.process(request) {
            switch event {
            case let .progress(progress):
                self.progress = paced(progress, elapsed: clock.now - start)
            case let .finished(result):
                // Время меряем до докрутки кольца: докрутка — это показ,
                // а не работа, и в отчёте она превратила бы любую обработку
                // в двухсекундную.
                analytics.didFinishRun(result, duration: clock.now - start)
                await settle(start: start, clock: clock)
                // Экран обработки из истории убираем: возврат с итога должен
                // вести на главную, а не запускать всё заново.
                router.setPath([outcome(result)])
            }
        }
    }

    /// Докручивает кольцо до конца за остаток минимального времени: иначе
    /// последним кадром был бы скачок с 20% сразу на экран итога.
    private func settle(start: ContinuousClock.Instant, clock: ContinuousClock) async {
        let full = ProcessingProgress(
            overall: 1,
            items: request.items.map { ItemProgress(id: $0.id, fraction: 1) },
            estimatedRemaining: .zero
        )

        while !Task.isCancelled {
            let elapsed = clock.now - start
            guard elapsed < Self.minimumRun else { break }
            progress = paced(full, elapsed: elapsed)
            try? await Task.sleep(for: .milliseconds(33))
        }

        progress = full
    }

    /// Придерживает показ темпом «круг за `minimumRun`». Доли отдельных файлов
    /// сжимаются тем же коэффициентом, чтобы очередь не разошлась с кольцом.
    private func paced(_ progress: ProcessingProgress, elapsed: Duration) -> ProcessingProgress {
        let cap = min(elapsed.seconds / Self.minimumRun.seconds, 1)
        guard progress.overall > cap else { return progress }
        let scale = cap / progress.overall
        return ProcessingProgress(
            overall: cap,
            items: progress.items.map { ItemProgress(id: $0.id, fraction: $0.fraction * scale) },
            estimatedRemaining: progress.estimatedRemaining
        )
    }

    public func cancel() {
        analytics.didCancelRun(percent: Int((progress.overall * 100).rounded()))
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
