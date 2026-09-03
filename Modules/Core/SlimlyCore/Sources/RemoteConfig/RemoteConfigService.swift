import Foundation

/// Удалённый конфиг: значения, которыми можно управлять без выпуска сборки.
///
/// Реализация отвечает только за сырую строку по имени — разбор и умолчание
/// одинаковы для всех источников и живут в расширении ниже.
public protocol RemoteConfigService: Sendable {
    /// `nil` — значения нет, владелец ключа получит своё умолчание.
    func text(for name: String) -> String?

    /// Забрать свежие значения. Молча: сорвавшаяся загрузка — это не ошибка
    /// экрана, а повод показать то, что уже есть.
    func refresh() async
}

public extension RemoteConfigService {
    func value<Value: RemoteConfigValue>(for key: RemoteConfigKey<Value>) -> Value {
        guard let text = text(for: key.name), let value = Value(remoteConfigText: text) else {
            return key.defaultValue
        }
        return value
    }
}

/// Конфиг без источника: отдаёт то, что положили руками, а всё остальное —
/// умолчаниями ключей.
///
/// На нём работают превью, тесты и сборка без `GoogleService-Info.plist`.
public struct LocalRemoteConfig: RemoteConfigService {
    private let values: [String: String]

    public init(values: [String: String] = [:]) {
        self.values = values
    }

    public func text(for name: String) -> String? {
        values[name]
    }

    public func refresh() async { }
}
