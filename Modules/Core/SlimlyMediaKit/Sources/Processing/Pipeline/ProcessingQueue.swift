import Foundation
import SlimlyCore

/// Очередь файлов одного задания.
protocol ProcessingQueueing: Sendable {
    /// `nil` — работу отменили: экрана, которому нужен итог, уже нет.
    func run(
        _ request: ProcessingRequest,
        progress: any ProgressReporting,
        simulatedFailure: String?
    ) async -> ProcessingOutcome?
}

/// Файл за файлом: у каждого исходника получается свой результат.
///
/// Файлы идут по очереди, а не разом: кодировщик у устройства один,
/// параллельная очередь только отняла бы у него память, а прогресс
/// превратила бы в дрожание нескольких полос сразу.
struct ProcessingQueue: ProcessingQueueing {
    private let items: any ItemProcessing

    init(items: any ItemProcessing) {
        self.items = items
    }

    func run(
        _ request: ProcessingRequest,
        progress: any ProgressReporting,
        simulatedFailure: String?
    ) async -> ProcessingOutcome? {
        var results: [ProcessingResult] = []
        var failures: [ProcessingFailure] = []

        for (index, item) in request.items.enumerated() {
            guard !Task.isCancelled else { return nil }

            if let simulatedFailure {
                failures.append(ProcessingFailure(item: item, message: simulatedFailure))
                progress.update(index: index, fraction: 1)
                continue
            }

            do {
                let result = try await items.process(item, operation: request.operation) { fraction in
                    progress.update(index: index, fraction: fraction)
                }
                results.append(result)
            } catch is CancellationError {
                return nil
            } catch {
                // Один битый файл не должен обрывать очередь: остальные
                // обработаются, а про этот честно скажем на экране итога.
                failures.append(ProcessingFailure(item: item, message: error.processingMessage))
            }

            progress.update(index: index, fraction: 1)
        }

        return ProcessingOutcome(request: request, results: results, failures: failures)
    }
}
