import Foundation

/// Хранилище значений по ключам.
///
/// Владелец значения знает только ключ и тип: где именно лежит отметка —
/// в `UserDefaults`, в памяти теста или в связке ключей — решает сборка
/// приложения, подставив другую реализацию.
public protocol KeyValueStorage: Sendable {
    func value<Value: StorageValue>(for key: StorageKey<Value>) -> Value?

    func set<Value: StorageValue>(_ value: Value, for key: StorageKey<Value>)

    func removeValue<Value: StorageValue>(for key: StorageKey<Value>)
}

public extension KeyValueStorage {
    /// Чтение со значением по умолчанию: «ключа нет» и «лежит false» для
    /// владельца — одно и то же, разделять их приходится редко.
    func value<Value: StorageValue>(for key: StorageKey<Value>, default fallback: Value) -> Value {
        value(for: key) ?? fallback
    }
}
