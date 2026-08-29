import Foundation

/// Сжатие и собственная база обработанного.
///
/// База своя, потому что iOS не помнит, что мы делали с файлами: всё,
/// что показано в профиле, приложение записало о себе само.
public protocol CompressionService: Sendable {
    func stats() async -> CompressionStats
    func recentResults(limit: Int) async -> [CompressionResult]

    /// Поток событий обработки. Отмена потока останавливает работу —
    /// как и уход из приложения: фоновой обработки здесь нет.
    func compress(_ items: [MediaItem], options: CompressionOptions) -> AsyncStream<CompressionEvent>
}

/// Заглушка: считает результат по коэффициенту пресета и проигрывает
/// правдоподобный прогресс, чтобы экран обработки жил по-настоящему.
public actor StubCompressionService: CompressionService {
    /// Шаг ленты прогресса — на глаз неотличим от непрерывного движения.
    private static let tick = Duration.milliseconds(55)
    private static let stepPerTick = 0.022

    private var currentStats: CompressionStats
    private var history: [CompressionResult]

    public init() {
        currentStats = CompressionStats(
            originalByteCount: .gigabytes(6.2),
            compressedByteCount: .gigabytes(2.8),
            photoCount: 104,
            videoCount: 24,
            heicConvertedCount: 31,
            streakDays: 3
        )
        history = [
            CompressionResult(
                item: MediaItem(id: "h1", kind: .video, fileName: "IMG_4102.MOV", byteCount: .megabytes(840), duration: .seconds(184)),
                compressedByteCount: .megabytes(302)
            ),
            CompressionResult(
                item: MediaItem(id: "h2", kind: .photo, fileName: "IMG_4098.HEIC", byteCount: .megabytes(5.1), isHEIC: true),
                compressedByteCount: .megabytes(1.9)
            ),
            CompressionResult(
                item: MediaItem(id: "h3", kind: .video, fileName: "IMG_4051.MOV", byteCount: .megabytes(210), duration: .seconds(96)),
                compressedByteCount: .megabytes(96)
            ),
        ]
    }

    public func stats() -> CompressionStats { currentStats }

    public func recentResults(limit: Int) -> [CompressionResult] { Array(history.prefix(limit)) }

    public nonisolated func compress(
        _ items: [MediaItem],
        options: CompressionOptions
    ) -> AsyncStream<CompressionEvent> {
        AsyncStream { continuation in
            let task = Task {
                await run(items, options: options, into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        _ items: [MediaItem],
        options: CompressionOptions,
        into continuation: AsyncStream<CompressionEvent>.Continuation
    ) async {
        guard !items.isEmpty else {
            continuation.finish()
            return
        }

        var overall = 0.0
        while overall < 1 {
            guard !Task.isCancelled else {
                continuation.finish()
                return
            }
            continuation.yield(.progress(progress(overall: overall, items: items)))
            try? await Task.sleep(for: Self.tick)
            overall += Self.stepPerTick
        }

        let results = items.map {
            CompressionResult(
                item: $0,
                compressedByteCount: Int64(Double($0.byteCount) * options.preset.ratio)
            )
        }
        continuation.yield(.progress(progress(overall: 1, items: items)))
        continuation.yield(.finished(record(results, options: options)))
        continuation.finish()
    }

    /// Файлы обрабатываются по очереди, поэтому общий прогресс режется
    /// на равные доли: у i-го файла своя полоса заполняется, пока общий
    /// прогресс идёт от i/n до (i+1)/n.
    private func progress(overall: Double, items: [MediaItem]) -> CompressionProgress {
        let count = Double(items.count)
        let perItem = items.enumerated().map { index, item in
            ItemProgress(
                id: item.id,
                fraction: min(max((overall - Double(index) / count) * count, 0), 1)
            )
        }
        return CompressionProgress(
            overall: min(overall, 1),
            items: perItem,
            estimatedRemaining: .seconds(max(1, Int(((1 - overall) * 40).rounded(.up))))
        )
    }

    private func record(_ results: [CompressionResult], options: CompressionOptions) -> CompressionOutcome {
        let before = currentStats
        currentStats = currentStats.adding(results, options: options)
        history.insert(contentsOf: results, at: 0)

        let unlocked = Achievement.catalogue.filter {
            !$0.isEarned(in: before) && $0.isEarned(in: currentStats)
        }
        return CompressionOutcome(results: results, options: options, unlockedAchievements: unlocked)
    }
}
