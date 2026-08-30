import Foundation

/// Хранилище статистики обработки.
///
/// Считает только приложение и только за себя: медиатека о наших сжатиях
/// ничего не знает, поэтому цифры профиля живут в `UserDefaults` рядом
/// с настройками, а не выводятся из библиотеки.
public actor ProcessingStatsStore {
    private static let key = "slimly.processing.stats"

    private let defaults: UserDefaults
    private var cached: ProcessingStats

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cached = Self.load(from: defaults) ?? .empty
    }

    public func stats() -> ProcessingStats { cached }

    @discardableResult
    public func add(_ outcome: ProcessingOutcome) -> ProcessingStats {
        cached = cached.adding(outcome)
        save()
        return cached
    }

    public func reset() {
        cached = .empty
        defaults.removeObject(forKey: Self.key)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: Self.key)
    }

    private static func load(from defaults: UserDefaults) -> ProcessingStats? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ProcessingStats.self, from: data)
    }
}
