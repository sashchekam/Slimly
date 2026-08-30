import Foundation
import SlimlyCore

/// Настоящая обработка файлов.
///
/// Файлы идут по очереди, а не разом: кодировщик у устройства один,
/// параллельная очередь только отняла бы у него память, а прогресс
/// превратила бы в дрожание нескольких полос сразу.
public final class MediaProcessor: MediaProcessingService, @unchecked Sendable {
    private let library: any MediaLibrary
    private let statsStore: ProcessingStatsStore
    private let output: OutputStore

    public init(library: any MediaLibrary, statsStore: ProcessingStatsStore = ProcessingStatsStore()) {
        self.library = library
        self.statsStore = statsStore
        output = OutputStore(library: library)
        OutputStore.clearWorkDirectory()
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
        var results: [ProcessingResult] = []
        var failures: [ProcessingFailure] = []

        for (index, item) in request.items.enumerated() {
            guard !Task.isCancelled else {
                continuation.finish()
                return
            }

            do {
                let result = try await process(item, request: request) { fraction in
                    tracker.update(index: index, fraction: fraction)
                }
                results.append(result)
            } catch is CancellationError {
                continuation.finish()
                return
            } catch {
                // Один битый файл не должен обрывать очередь: остальные
                // обработаются, а про этот честно скажем на экране итога.
                failures.append(ProcessingFailure(item: item, message: message(for: error)))
            }

            tracker.update(index: index, fraction: 1)
        }

        let outcome = ProcessingOutcome(request: request, results: results, failures: failures)
        if !results.isEmpty {
            await statsStore.add(outcome)
        }

        continuation.yield(.finished(outcome))
        continuation.finish()
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: Один файл

    private func process(
        _ item: MediaItem,
        request: ProcessingRequest,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        let source = try await library.exportOriginal(item)
        defer { try? FileManager.default.removeItem(at: source) }

        switch request.operation {
        case let .compress(level):
            return try await compress(item, source: source, level: level, progress: progress)
        case let .convert(format):
            return try await convert(item, source: source, format: format, progress: progress)
        case let .extractAudio(format):
            return try await extractAudio(item, source: source, format: format, progress: progress)
        case .scan:
            throw ProcessingError.unsupportedOperation("Скан пока не реализован")
        }
    }

    /// Сжатие не меняет тип файла: HEIC остаётся HEIC, MOV — MOV.
    /// Иначе «сжать» незаметно превращалось бы в «сконвертировать».
    private func compress(
        _ item: MediaItem,
        source: URL,
        level: CompressionLevel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        switch item.kind {
        case .photo:
            let format = ImageFormat.matching(fileExtension: item.fileExtension)
            return try await produce(
                item,
                extension: format.fileExtension,
                destination: .photoLibrary
            ) { file in
                try ImagePipeline.write(
                    source: source,
                    to: file,
                    settings: ImagePipeline.Settings(
                        format: format,
                        quality: EncodingSettings.imageQuality(level),
                        maxPixelSize: EncodingSettings.imageMaxPixelSize(level)
                    )
                )
                progress(1)
            }

        case .video:
            let container: VideoContainer = item.fileExtension == "mp4" ? .mp4 : .mov
            let codec = await MediaTranscoder.videoCodec(of: source) ?? .hevc
            return try await produce(
                item,
                extension: container.fileExtension,
                destination: .photoLibrary
            ) { file in
                try await MediaTranscoder.transcodeVideo(
                    source: source,
                    destination: file,
                    settings: MediaTranscoder.VideoSettings(
                        container: container,
                        codec: codec,
                        shortSideLimit: EncodingSettings.videoShortSide(level),
                        bitrateFactor: EncodingSettings.videoBitrateFactor(level)
                    ),
                    progress: progress
                )
            }
        }
    }

    private func convert(
        _ item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        switch format.target {
        case let .image(target):
            guard item.kind == .photo else {
                throw ProcessingError.unsupportedOperation("Видео нельзя сохранить как \(target.displayName)")
            }
            return try await produce(
                item,
                extension: target.fileExtension,
                destination: .photoLibrary
            ) { file in
                try ImagePipeline.write(
                    source: source,
                    to: file,
                    settings: ImagePipeline.Settings(
                        format: target,
                        // Смена формата не должна портить кадр: качество
                        // высокое, размер не трогаем.
                        quality: 0.9,
                        maxPixelSize: nil
                    )
                )
                progress(1)
            }

        case let .video(container, codec):
            guard item.kind == .video else {
                throw ProcessingError.unsupportedOperation("Фото нельзя сохранить как \(container.displayName)")
            }
            return try await produce(
                item,
                extension: container.fileExtension,
                destination: .photoLibrary
            ) { file in
                try await MediaTranscoder.transcodeVideo(
                    source: source,
                    destination: file,
                    settings: MediaTranscoder.VideoSettings(
                        container: container,
                        codec: codec,
                        shortSideLimit: nil,
                        // HEVC при том же качестве требует меньше битрейта —
                        // ровно на столько, сколько обещает оценка формата.
                        bitrateFactor: format.ratio
                    ),
                    progress: progress
                )
            }

        case .audio, .document:
            throw ProcessingError.unsupportedOperation("Формат \(format.id) недоступен для конвертации")
        }
    }

    private func extractAudio(
        _ item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        guard case let .audio(target) = format.target, item.kind == .video else {
            throw ProcessingError.unsupportedOperation("Звук извлекается только из видео")
        }

        return try await produce(item, extension: target.fileExtension, destination: .files) { file in
            try await MediaTranscoder.extractAudio(
                source: source,
                destination: file,
                format: target,
                progress: progress
            )
        }
    }

    /// Записать результат и разложить его по месту.
    ///
    /// Недописанный файл после ошибки или отмены не должен пережить попытку:
    /// иначе кэш копит куски, которые ни показать, ни сохранить.
    private func produce(
        _ item: MediaItem,
        extension ext: String,
        destination: OutputDestination,
        write: (URL) async throws -> Void
    ) async throws -> ProcessingResult {
        let file = try output.makeWorkFile(extension: ext)

        do {
            try await write(file)

            let name = "\(item.baseName).\(ext)"
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let stored = try await output.store(
                file,
                kind: item.kind,
                name: name,
                destination: destination
            )

            return ProcessingResult(
                item: item,
                outputByteCount: Int64(size),
                outputName: name,
                outputURL: stored,
                destination: destination
            )
        } catch {
            try? FileManager.default.removeItem(at: file)
            throw error
        }
    }
}

/// Счётчик прогресса очереди.
///
/// Доли считаются по весу файлов, а не по их количеству: видео на 600 МБ
/// и фото на 4 МБ — не половина работы каждая, и равномерная полоса
/// на такой паре выглядела бы враньём.
private final class ProgressTracker: @unchecked Sendable {
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

        let total = Double(items.totalByteCount)
        weights = total > 0
            ? items.map { Double($0.byteCount) / total }
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
