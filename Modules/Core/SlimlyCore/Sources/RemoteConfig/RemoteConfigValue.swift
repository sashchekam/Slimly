import Foundation

/// Тип, который умеет приехать из удалённого конфига.
///
/// Значение приходит строкой — так его отдаёт и Firebase, и любой другой
/// источник, и такой же строкой оно набирается руками в веб-консоли.
/// Разбор живёт на самом типе, поэтому владелец ключа получает готовое
/// значение, а не строку с приведением на месте.
public protocol RemoteConfigValue: Sendable {
    init?(remoteConfigText: String)
}

extension String: RemoteConfigValue {
    public init?(remoteConfigText: String) {
        self = remoteConfigText
    }
}

extension Int: RemoteConfigValue {
    public init?(remoteConfigText: String) {
        self.init(remoteConfigText)
    }
}

extension Double: RemoteConfigValue {
    public init?(remoteConfigText: String) {
        self.init(remoteConfigText)
    }
}

extension Bool: RemoteConfigValue {
    /// В веб-консоли флаг набирают по-разному — «true», «1», «yes».
    /// Ошибка в написании не должна тихо превращаться в противоположный
    /// флаг, поэтому всё непонятное — это «значения нет».
    public init?(remoteConfigText: String) {
        switch remoteConfigText.lowercased() {
        case "true", "yes", "1": self = true
        case "false", "no", "0": self = false
        default: return nil
        }
    }
}
