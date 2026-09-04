import FirebaseRemoteConfig
import Foundation
import OSLog
import SlimlyCore

/// Удалённый конфиг на Firebase.
///
/// Умолчания в SDK не регистрируются: они живут в самих ключах
/// (`RemoteConfigKey`), и «значения нет» здесь — это просто `nil`.
/// Иначе одно и то же умолчание пришлось бы держать в двух местах.
public struct FirebaseRemoteConfigService: RemoteConfigService {
    private static let logger = Logger(subsystem: "com.slimly", category: "remote-config")

    /// Конфиг берётся по месту, а не хранится полем: `RemoteConfig` не
    /// `Sendable`, и полем он запретил бы сервису пересекать потоки.
    /// Экземпляр у SDK всё равно один на приложение, и потоки он разводит сам.
    private var config: RemoteConfig { RemoteConfig.remoteConfig() }

    public init() {
        #if DEBUG
        // По умолчанию SDK держит кэш двенадцать часов: правку в веб-консоли
        // до конца этого срока в отладочной сборке просто не увидеть.
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        config.configSettings = settings
        #endif
    }

    /// Только загруженные значения: умолчания в SDK не регистрируются,
    /// и всё, что здесь перечислено, действительно пришло с сервера.
    public var names: [String] {
        config.allKeys(from: .remote).sorted()
    }

    public func text(for name: String) -> String? {
        let value = config.configValue(forKey: name)
        // `.static` — ключа нет ни в загруженном конфиге, ни в умолчаниях SDK:
        // пустая строка тут значила бы «значение задано пустым».
        guard value.source != .static else { return nil }

        let text = value.stringValue
        return text.isEmpty ? nil : text
    }

    public func refresh() async {
        do {
            let status = try await config.fetchAndActivate()
            Self.logger.debug("конфиг обновлён: \(String(describing: status), privacy: .public)")
        } catch {
            // Молча: экран показывает то, что уже есть, а не ошибку сети.
            Self.logger.warning("конфиг не обновился: \(error.localizedDescription, privacy: .public)")
        }
    }
}
