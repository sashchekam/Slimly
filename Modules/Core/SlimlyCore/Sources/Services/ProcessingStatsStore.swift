import Foundation

extension ProcessingStats: CodableStorageValue { }

public extension StorageKey where Value == ProcessingStats {
    static var processingStats: StorageKey { StorageKey("slimly.processing.stats") }
}

/// Хранилище статистики обработки.
///
/// Считает только приложение и только за себя: медиатека о наших сжатиях
/// ничего не знает, поэтому цифры профиля живут рядом с настройками,
/// а не выводятся из библиотеки.
public actor ProcessingStatsStore {
    private let storage: any KeyValueStorage
    private var cached: ProcessingStats

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
        cached = storage.value(for: .processingStats, default: .empty)
    }

    public func stats() -> ProcessingStats { cached }

    @discardableResult
    public func add(_ outcome: ProcessingOutcome) -> ProcessingStats {
        cached = cached.adding(outcome)
        storage.set(cached, for: .processingStats)
        return cached
    }

    public func reset() {
        cached = .empty
        storage.removeValue(for: .processingStats)
    }
}
