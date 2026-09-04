import Foundation

/// Локальные подмены удалённого конфига: имя ключа → текст значения.
///
/// Подмена живёт только на этом устройстве и никуда не уезжает: это способ
/// посмотреть на поведение флага у себя, не трогая веб-консоль и остальных.
/// Значение здесь строкой, как и в самом конфиге, — разбирать его будет
/// владелец ключа, а не хранилище подмен.
public struct RemoteConfigOverrides: CodableStorageValue {
    private var values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }

    public var names: [String] {
        values.keys.sorted()
    }

    public var isEmpty: Bool {
        values.isEmpty
    }

    public subscript(name: String) -> String? {
        get { values[name] }
        set { values[name] = newValue }
    }
}

public extension StorageKey where Value == RemoteConfigOverrides {
    static var remoteConfigOverrides: StorageKey { StorageKey("slimly.debug.remoteConfigOverrides") }
}
