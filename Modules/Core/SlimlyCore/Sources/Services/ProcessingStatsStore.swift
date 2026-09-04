import Foundation

extension ProcessingStats: CodableStorageValue { }

extension ProcessingHistory: CodableStorageValue { }

public extension StorageKey where Value == ProcessingStats {
    static var processingStats: StorageKey { StorageKey("slimly.processing.stats") }
}

public extension StorageKey where Value == ProcessingHistory {
    static var processingHistory: StorageKey { StorageKey("slimly.processing.history") }
}

/// Хранилище статистики обработки.
///
/// Считает только приложение и только за себя: медиатека о наших сжатиях
/// ничего не знает, поэтому цифры профиля живут рядом с настройками,
/// а не выводятся из библиотеки.
///
/// Хранится и общая сумма, и журнал работ. Сумма не выводится из журнала
/// намеренно: журнал подрезается по краю, а «освобождено с первого запуска»
/// от этого меняться не должно.
public actor ProcessingStatsStore {
    private let storage: any KeyValueStorage
    private var cached: ProcessingStats
    private var cachedHistory: ProcessingHistory

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
        cached = storage.value(for: .processingStats, default: .empty)
        cachedHistory = storage.value(for: .processingHistory, default: .empty)
    }

    public func stats() -> ProcessingStats { cached }

    public func history() -> ProcessingHistory { cachedHistory }

    @discardableResult
    public func add(_ outcome: ProcessingOutcome) -> ProcessingStats {
        cached = cached.adding(outcome)
        storage.set(cached, for: .processingStats)

        // В журнал попадает всё, включая скан: разрез по инструментам
        // без него был бы неполным, хотя в весе скану считаться нечем.
        cachedHistory = cachedHistory.appending(ProcessingRecord(outcome))
        storage.set(cachedHistory, for: .processingHistory)

        return cached
    }

    public func reset() {
        cached = .empty
        cachedHistory = .empty
        storage.removeValue(for: .processingStats)
        storage.removeValue(for: .processingHistory)
    }
}
