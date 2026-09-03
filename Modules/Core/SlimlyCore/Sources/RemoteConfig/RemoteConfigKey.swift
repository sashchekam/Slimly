import Foundation

/// Ключ удалённого конфига вместе со значением по умолчанию.
///
/// Умолчание лежит рядом с именем, а не на месте чтения: до первой удачной
/// загрузки, без сети и без Firebase значение всё равно нужно, и оно должно
/// быть одно на всё приложение.
public struct RemoteConfigKey<Value: RemoteConfigValue>: Sendable {
    public let name: String
    public let defaultValue: Value

    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
