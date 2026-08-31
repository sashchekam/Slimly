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

        #if DEBUG
        // Подмена из отладочного меню. Дождаться настоящего отказа от системы
        // почти нельзя — место кончается редко, — а список отказов на экране
        // итога проверять надо.
        let simulatedFailure = SimulatedFailure.stored().reason
        #else
        let simulatedFailure: String? = nil
        #endif

        // Скан идёт своей дорогой: из пачки снимков получается один документ,
        // а не файл на каждый файл, — и поштучная очередь для него не годится.
        let outcome: ProcessingOutcome?
        if case let .scan(format) = request.operation, case let .document(mode) = format.target {
            outcome = await assembleScan(
                request,
                mode: mode,
                tracker: tracker,
                simulatedFailure: simulatedFailure
            )
        } else {
            outcome = await processEach(
                request,
                tracker: tracker,
                simulatedFailure: simulatedFailure
            )
        }

        // `nil` — работу отменили: экрана, которому нужен итог, уже нет.
        guard let outcome else {
            continuation.finish()
            return
        }

        if !outcome.results.isEmpty {
            await statsStore.add(outcome)
        }

        continuation.yield(.finished(outcome))
        continuation.finish()
    }

    /// Файл за файлом: у каждого исходника получается свой результат.
    private func processEach(
        _ request: ProcessingRequest,
        tracker: ProgressTracker,
        simulatedFailure: String?
    ) async -> ProcessingOutcome? {
        var results: [ProcessingResult] = []
        var failures: [ProcessingFailure] = []

        for (index, item) in request.items.enumerated() {
            guard !Task.isCancelled else { return nil }

            if let simulatedFailure {
                failures.append(ProcessingFailure(item: item, message: simulatedFailure))
                tracker.update(index: index, fraction: 1)
                continue
            }

            do {
                let result = try await process(item, request: request) { fraction in
                    tracker.update(index: index, fraction: fraction)
                }
                results.append(result)
            } catch is CancellationError {
                return nil
            } catch {
                // Один битый файл не должен обрывать очередь: остальные
                // обработаются, а про этот честно скажем на экране итога.
                failures.append(ProcessingFailure(item: item, message: message(for: error)))
            }

            tracker.update(index: index, fraction: 1)
        }

        return ProcessingOutcome(request: request, results: results, failures: failures)
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
            // Страница обрабатывается не сама по себе, а вместе с документом:
            // сюда очередь скана не заходит.
            throw ProcessingError.unsupportedOperation("Страница собирается вместе с документом")
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

    // MARK: Скан

    /// Доля прогресса страницы, приходящаяся на её подготовку. Остаток —
    /// сборка PDF: она одна на весь документ, и до её конца ни одна
    /// страница по-настоящему не готова.
    private static let pagePreparationShare = 0.9

    /// Пачка снимков → один документ.
    ///
    /// Нечитаемый снимок документ не отменяет: соберём PDF из тех страниц,
    /// что получились, а про пропущенные скажем на экране итога.
    private func assembleScan(
        _ request: ProcessingRequest,
        mode: ScanMode,
        tracker: ProgressTracker,
        simulatedFailure: String?
    ) async -> ProcessingOutcome? {
        var prepared: [(item: MediaItem, page: ScannedPage)] = []
        var failures: [ProcessingFailure] = []

        for (index, item) in request.items.enumerated() {
            guard !Task.isCancelled else { return nil }

            if let simulatedFailure {
                failures.append(ProcessingFailure(item: item, message: simulatedFailure))
                tracker.update(index: index, fraction: 1)
                continue
            }

            do {
                let page = try await preparePage(item, mode: mode)
                prepared.append((item, page))
                tracker.update(index: index, fraction: Self.pagePreparationShare)
            } catch is CancellationError {
                return nil
            } catch {
                failures.append(ProcessingFailure(item: item, message: message(for: error)))
                tracker.update(index: index, fraction: 1)
            }
        }

        guard let cover = prepared.first?.item else {
            return ProcessingOutcome(request: request, results: [], failures: failures)
        }

        do {
            let document = try await assembleDocument(prepared.map(\.page), cover: cover)
            for index in request.items.indices {
                tracker.update(index: index, fraction: 1)
            }
            return ProcessingOutcome(request: request, results: [document], failures: failures)
        } catch {
            // Документ не собрался — значит, не вышло ни одной страницы:
            // по отдельности они никуда не сохраняются.
            let reason = message(for: error)
            failures.append(
                contentsOf: prepared.map { ProcessingFailure(item: $0.item, message: reason) }
            )
            return ProcessingOutcome(request: request, results: [], failures: failures)
        }
    }

    private func preparePage(_ item: MediaItem, mode: ScanMode) async throws -> ScannedPage {
        let source = try await library.exportOriginal(item)
        defer { try? FileManager.default.removeItem(at: source) }
        return try DocumentScanner.page(at: source, mode: mode)
    }

    /// Документ ложится в «Файлы»: PDF в медиатеке не место, да iOS туда его
    /// и не примет.
    ///
    /// - Parameter cover: первая удавшаяся страница. Результат у скана один
    ///   на весь заказ, а ``ProcessingResult`` привязан к исходнику — берём
    ///   ту страницу, что открывается в PDF первой: её превью и увидят
    ///   в списке итога.
    private func assembleDocument(_ pages: [ScannedPage], cover: MediaItem) async throws -> ProcessingResult {
        let name = Self.documentName()
        let file = try output.makeWorkFile(extension: "pdf")

        do {
            try PDFBuilder.write(
                pages: pages,
                to: file,
                title: (name as NSString).deletingPathExtension
            )

            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let stored = try await output.store(
                file,
                kind: cover.kind,
                name: name,
                destination: .files
            )

            return ProcessingResult(
                item: cover,
                outputByteCount: Int64(size),
                outputName: name,
                outputURL: stored,
                destination: .files
            )
        } catch {
            try? FileManager.default.removeItem(at: file)
            throw error
        }
    }

    /// «Скан 2026-08-30 14-23.pdf».
    ///
    /// Дата в имени, потому что своего имени у документа нет: страницы
    /// приходят из медиатеки под номерами камеры, а сканов в папке
    /// со временем накапливается много.
    private static func documentName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        // Двоеточие «Файлы» показывают косой чертой — время разделяем дефисом.
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        return "Скан \(formatter.string(from: .now)).pdf"
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
