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

/// Значение, которое приезжает не числом и не флагом, а объектом JSON.
///
/// Отдельный протокол, а не `where Self: Decodable`, — по той же причине,
/// что и у `CodableStorageValue`: `Decodable` есть и у примитивов, и выбор
/// реализации стал бы неочевидным.
///
/// Набор связанных значений так и правят — вместе, одним полем в веб-консоли:
/// у каждого поля своё умолчание в самом типе, поэтому неполный и даже
/// испорченный объект оставляет остальные значения на месте.
public protocol JSONRemoteConfigValue: RemoteConfigValue, Decodable { }

public extension JSONRemoteConfigValue {
    init?(remoteConfigText: String) {
        guard let data = remoteConfigText.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }

        self = value
    }
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
