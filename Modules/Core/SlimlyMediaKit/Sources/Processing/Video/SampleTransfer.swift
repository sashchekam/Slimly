import AVFoundation
import Foundation

/// Одна дорожка перекачки: откуда читаем и куда пишем.
struct TransferLeg {
    let input: AVAssetWriterInput
    let output: AVAssetReaderOutput
    /// Прогресс считаем по одной дорожке — обычно по видео: звук
    /// кодируется быстрее и обгонял бы картинку.
    let reportsProgress: Bool
}

/// Перекачка сэмплов из читателя в писателя.
protocol SampleTransferring: Sendable {
    func run(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        legs: [TransferLeg],
        seconds: Double,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws
}

/// Сам воркер без состояния: всё, что живёт только на время одной перекачки,
/// уходит в ``TransferSession`` — иначе воркер нельзя было бы держать
/// в поле и переиспользовать.
struct SampleTransfer: SampleTransferring {
    func run(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        legs: [TransferLeg],
        seconds: Double,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await TransferSession(
            reader: reader,
            writer: writer,
            legs: legs,
            seconds: seconds,
            progress: progress
        ).run()
    }
}

/// Одна перекачка от начала до конца.
///
/// `@unchecked Sendable` здесь честный: объекты AVFoundation живут только
/// внутри этого класса и трогаются исключительно из блоков
/// `requestMediaDataWhenReady`, а общее изменяемое состояние — три поля
/// под одним замком.
private final class TransferSession: @unchecked Sendable {
    private let reader: AVAssetReader
    private let writer: AVAssetWriter
    private let legs: [TransferLeg]
    private let seconds: Double
    private let progress: @Sendable (Double) -> Void

    private let lock = NSLock()
    private var finishedLegs: Set<Int> = []
    private var isCancelled = false
    private var reportedFraction = 0.0

    init(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        legs: [TransferLeg],
        seconds: Double,
        progress: @escaping @Sendable (Double) -> Void
    ) {
        self.reader = reader
        self.writer = writer
        self.legs = legs
        self.seconds = seconds
        self.progress = progress
    }

    func run() async throws {
        guard writer.startWriting() else {
            let reason = L10n.Reason.writerNotStarted
            throw writer.error ?? ProcessingError.encodingFailed(reason)
        }
        guard reader.startReading() else {
            writer.cancelWriting()
            throw reader.error ?? ProcessingError.unreadableSource
        }
        writer.startSession(atSourceTime: .zero)

        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let group = DispatchGroup()
                for index in legs.indices {
                    group.enter()
                    let queue = DispatchQueue(label: "com.slimly.transfer.\(index)")
                    legs[index].input.requestMediaDataWhenReady(on: queue) { [self] in
                        pump(at: index) { group.leave() }
                    }
                }
                group.notify(queue: .global(qos: .userInitiated)) { continuation.resume() }
            }
        } onCancel: {
            cancel()
        }

        if Task.isCancelled {
            writer.cancelWriting()
            throw CancellationError()
        }

        if reader.status == .failed {
            writer.cancelWriting()
            throw reader.error ?? ProcessingError.unreadableSource
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting { continuation.resume() }
        }

        guard writer.status == .completed else {
            let reason = L10n.Reason.notFinalized
            throw writer.error ?? ProcessingError.encodingFailed(reason)
        }
        progress(1)
    }

    // MARK: Перекачка

    private func pump(at index: Int, done: @escaping () -> Void) {
        let leg = legs[index]
        guard !isFinished(index) else { return }

        while leg.input.isReadyForMoreMediaData {
            guard !cancelled(), let sample = leg.output.copyNextSampleBuffer() else {
                finish(index, done: done)
                return
            }

            if leg.reportsProgress { report(sample) }

            guard leg.input.append(sample) else {
                finish(index, done: done)
                return
            }
        }
    }

    /// Дорожка завершается ровно один раз: блок готовности зовут повторно,
    /// а `leave()` без парного `enter()` роняет группу.
    private func finish(_ index: Int, done: () -> Void) {
        lock.lock()
        let isNew = finishedLegs.insert(index).inserted
        lock.unlock()

        guard isNew else { return }
        legs[index].input.markAsFinished()
        done()
    }

    private func report(_ sample: CMSampleBuffer) {
        guard seconds > 0 else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
        guard time.isFinite else { return }

        let fraction = min(max(time / seconds, 0), 1)
        lock.lock()
        // Кадров десятки в секунду, а полоса на экране — пиксели:
        // сообщаем не чаще, чем это видно.
        let shouldReport = fraction - reportedFraction >= 0.01
        if shouldReport { reportedFraction = fraction }
        lock.unlock()

        if shouldReport { progress(fraction) }
    }

    private func cancel() {
        lock.lock()
        isCancelled = true
        lock.unlock()
        reader.cancelReading()
    }

    private func cancelled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }

    private func isFinished(_ index: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return finishedLegs.contains(index)
    }
}
