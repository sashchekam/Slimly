import Foundation

/// Источник конфига, поверх которого лежат локальные подмены.
///
/// Собирается только в отладочной сборке: в релизе подменять значения нечем,
/// и приложение читает источник напрямую.
///
/// Подмены берутся из хранилища на каждом обращении, а не кэшируются полем:
/// правит их отладочное меню с главного потока, а значение спрашивают откуда
/// угодно — общее изменяемое поле пришлось бы держать под замком ради пары
/// чтений за экран.
public struct OverridingRemoteConfig: RemoteConfigService {
    private let base: any RemoteConfigService
    private let storage: any KeyValueStorage

    public init(base: any RemoteConfigService, storage: any KeyValueStorage = DefaultsStorage()) {
        self.base = base
        self.storage = storage
    }

    /// Подменить можно и то, чего в источнике нет: ключ мог ещё не доехать
    /// до веб-консоли, а проверить поведение нужно уже сейчас.
    public var names: [String] {
        Set(base.names + overrides.names).sorted()
    }

    private var overrides: RemoteConfigOverrides {
        storage.value(for: .remoteConfigOverrides, default: RemoteConfigOverrides())
    }

    public func text(for name: String) -> String? {
        overrides[name] ?? base.text(for: name)
    }

    public func refresh() async {
        await base.refresh()
    }
}
