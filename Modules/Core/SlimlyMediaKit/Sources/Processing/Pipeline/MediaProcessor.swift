import Foundation
import SlimlyCore

/// Настоящая обработка файлов.
///
/// Сам ничего не кодирует и не пишет: держит очередь, считает прогресс
/// и раздаёт работу воркерам — очереди файлов, сборщику скана и хранилищу
/// результата.
public final class MediaProcessor: MediaProcessingService, @unchecked Sendable {
    private let statsStore: ProcessingStatsStore
    private let output: any OutputStoring
    private let queue: any ProcessingQueueing
    private let scans: any ScanAssembling
    private let simulatedFailure: any SimulatedFailureProviding

    init(
        statsStore: ProcessingStatsStore,
        output: any OutputStoring,
        queue: any ProcessingQueueing,
        scans: any ScanAssembling,
        workFiles: any WorkFileProviding,
        simulatedFailure: any SimulatedFailureProviding
    ) {
        self.statsStore = statsStore
        self.output = output
        self.queue = queue
        self.scans = scans
        self.simulatedFailure = simulatedFailure
        workFiles.clear()
    }

    /// Состав по умолчанию: всё, что нужно снаружи, — медиатека, из которой
    /// приходят оригиналы и в которую возвращается результат.
    public convenience init(
        library: any MediaLibrary,
        statsStore: ProcessingStatsStore = ProcessingStatsStore()
    ) {
        self.init(
            statsStore: statsStore,
            output: OutputStore(library: library),
            queue: ProcessingQueue(items: MediaItemProcessor(library: library)),
            scans: ScanAssembler(library: library),
            workFiles: WorkDirectory(),
            simulatedFailure: SimulatedFailureProvider()
        )
    }

    public func stats() async -> ProcessingStats {
        await statsStore.stats()
    }

    public func process(_ request: ProcessingRequest) -> AsyncStream<ProcessingEvent> {
        AsyncStream { continuation in
            let task = Task { await run(request, into: continuation) }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Вынести готовые файлы наружу — по кнопке на экране итога.
    ///
    /// Здесь же учитывается статистика: до сохранения ничего не освобождено
    /// и никуда не положено, а профиль считает сделанное, а не проделанное.
    public func save(_ outcome: ProcessingOutcome) async -> ProcessingOutcome {
        var saved: [ProcessingResult] = []
        var failures = outcome.failures

        for result in outcome.results {
            do {
                guard let file = result.outputURL else { throw ProcessingError.outputMissing }

                let stored = try await output.store(
                    file,
                    kind: result.item.kind,
                    name: result.outputName,
                    destination: result.destination
                )
                saved.append(result.stored(at: stored))
            } catch {
                failures.append(ProcessingFailure(item: result.item, message: error.processingMessage))
            }
        }

        let stored = ProcessingOutcome(request: outcome.request, results: saved, failures: failures)

        if !saved.isEmpty {
            await statsStore.add(stored)
        }

        return stored
    }

    // MARK: Очередь

    private func run(
        _ request: ProcessingRequest,
        into continuation: AsyncStream<ProcessingEvent>.Continuation
    ) async {
        guard !request.items.isEmpty else {
            continuation.finish()
            return
        }

        let tracker = ProgressTracker(items: request.items, continuation: continuation)
        let failure = simulatedFailure.reason()

        let outcome: ProcessingOutcome?
        if case let .scan(format, bounds) = request.operation, case let .document(mode) = format.target {
            outcome = await scans.assemble(
                request,
                mode: mode,
                bounds: bounds,
                progress: tracker,
                simulatedFailure: failure
            )
        } else {
            outcome = await queue.run(request, progress: tracker, simulatedFailure: failure)
        }

        // `nil` — работу отменили: экрана, которому нужен итог, уже нет.
        guard let outcome else {
            continuation.finish()
            return
        }

        continuation.yield(.finished(outcome))
        continuation.finish()
    }
}
