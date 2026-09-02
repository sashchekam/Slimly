import Foundation

/// Хранилище поверх `UserDefaults` — то, что стоит в приложении.
///
/// `@unchecked` — потому что `UserDefaults` потокобезопасен по контракту,
/// но `Sendable` в SDK не помечен.
public struct DefaultsStorage: KeyValueStorage, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func value<Value: StorageValue>(for key: StorageKey<Value>) -> Value? {
        guard let object = defaults.object(forKey: key.name) else { return nil }

        return candidates(for: object)
            .lazy
            .compactMap(Value.init(stored:))
            .first
    }

    public func set<Value: StorageValue>(_ value: Value, for key: StorageKey<Value>) {
        switch value.stored {
        case let .bool(value): defaults.set(value, forKey: key.name)
        case let .int(value): defaults.set(value, forKey: key.name)
        case let .double(value): defaults.set(value, forKey: key.name)
        case let .string(value): defaults.set(value, forKey: key.name)
        case let .data(value): defaults.set(value, forKey: key.name)
        }
    }

    public func removeValue<Value: StorageValue>(for key: StorageKey<Value>) {
        defaults.removeObject(forKey: key.name)
    }

    /// `UserDefaults` возвращает числа одним `NSNumber`, и отличить в нём
    /// сохранённый `Bool` от `Int` нельзя. Поэтому число предлагается типу
    /// во всех трёх видах: подойдёт ровно один — тот, которым писали.
    private func candidates(for object: Any) -> [StoredValue] {
        switch object {
        case let value as Data: [.data(value)]
        case let value as String: [.string(value)]
        case let value as NSNumber: [.bool(value.boolValue), .int(value.intValue), .double(value.doubleValue)]
        default: []
        }
    }
}
