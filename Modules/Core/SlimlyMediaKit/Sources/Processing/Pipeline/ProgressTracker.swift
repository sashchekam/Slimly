import Foundation
import SlimlyCore

/// Куда очередь сообщает, насколько готов очередной файл.
protocol ProgressReporting: Sendable {
    func update(index: Int, fraction: Double)
}

/// Счётчик прогресса очереди.
///
/// Доли считаются по весу файлов, а не по их количеству: видео на 600 МБ
/// и фото на 4 МБ — не половина работы каждая, и равномерная полоса
/// на такой паре выглядела бы враньём.
final class ProgressTracker: ProgressReporting, @unchecked Sendable {
    private let items: [MediaItem]
    private let weights: [Double]
    private let continuation: AsyncStream<ProcessingEvent>.Continuation
    private let started = ContinuousClock.now

    private let lock = NSLock()
    private var fractions: [Double]

    init(items: [MediaItem], continuation: AsyncStream<ProcessingEvent>.Continuation) {
        self.items = items
        self.continuation = continuation
        fractions = Array(repeating: 0, count: items.count)

        // Доля работы, а не доля веса в галерее: перекодировать придётся
        // ровно то, что уходит в обработку.
        let total = Double(items.totalSourceByteCount)
        weights = total > 0
            ? items.map { Double($0.sourceByteCount) / total }
            : Array(repeating: 1 / Double(max(items.count, 1)), count: items.count)
    }

    func update(index: Int, fraction: Double) {
        lock.lock()
        guard index < fractions.count, fraction > fractions[index] else {
            lock.unlock()
            return
        }
        fractions[index] = min(fraction, 1)
        let overall = zip(fractions, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let snapshot = fractions
        lock.unlock()

        continuation.yield(
            .progress(
                ProcessingProgress(
                    overall: min(overall, 1),
                    items: zip(items, snapshot).map { ItemProgress(id: $0.id, fraction: $1) },
                    estimatedRemaining: remaining(overall: overall)
                )
            )
        )
    }

    /// Прогноз строим по уже потраченному времени. Пока сделано меньше
    /// пяти процентов, цифра прыгала бы от секунд до минут — тогда честнее
    /// не показывать её вовсе.
    private func remaining(overall: Double) -> Duration? {
        guard overall > 0.05, overall < 1 else { return nil }
        let elapsed = started.duration(to: .now)
        return elapsed * ((1 - overall) / overall)
    }
}
