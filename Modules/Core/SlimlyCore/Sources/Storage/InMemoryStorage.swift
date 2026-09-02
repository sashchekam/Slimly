import Foundation

/// Хранилище в памяти: превью и тесты, которым нужно чистое состояние
/// на каждый запуск и никаких следов на устройстве.
public final class InMemoryStorage: KeyValueStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: StoredValue]

    public init(values: [String: StoredValue] = [:]) {
        self.values = values
    }

    public func value<Value: StorageValue>(for key: StorageKey<Value>) -> Value? {
        lock.withLock { values[key.name] }.flatMap(Value.init(stored:))
    }

    public func set<Value: StorageValue>(_ value: Value, for key: StorageKey<Value>) {
        lock.withLock { values[key.name] = value.stored }
    }

    public func removeValue<Value: StorageValue>(for key: StorageKey<Value>) {
        lock.withLock { values[key.name] = nil }
    }
}
