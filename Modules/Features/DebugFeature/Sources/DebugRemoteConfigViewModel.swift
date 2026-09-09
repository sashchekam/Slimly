import DebugFeatureInterface
import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Что удалённый конфиг отдаёт прямо сейчас и чем это подменено на устройстве.
@MainActor
@Observable
public final class DebugRemoteConfigViewModel {
    /// Одно значение конфига: что пришло с сервера и что лежит поверх.
    public struct Entry: Identifiable, Sendable {
        /// Имя ключа — оно же идентификатор: одинаковых имён в конфиге нет.
        public let id: String
        public let remoteText: String?
        public let overrideText: String?

        public var isOverridden: Bool { overrideText != nil }

        /// Действующее значение, разложенное по строкам, — если в нём
        /// объект. Строка списка показывает его целиком, а не хвостом
        /// в углу: за коротким `{"scan_pages"…` не видно ничего.
        public let prettyValue: String?

        /// Действующее значение — то, что получит владелец ключа.
        /// Прочерк значит «источник промолчал»: в дело пойдёт умолчание
        /// самого ключа, а его знает только объявивший ключ код.
        public var value: String { overrideText ?? remoteText ?? "—" }

        public var isObject: Bool { prettyValue != nil }

        public var source: String {
            switch (isOverridden, remoteText) {
            case (true, .some):
                // Объект в подпись не помещается, да и лежит он строкой ниже.
                isObject ? L10n.Config.stateOverriddenShort : L10n.Config.stateOverridden(remoteText ?? "")
            case (true, .none):
                L10n.Config.stateOverriddenOnly
            case (false, .some): L10n.Config.stateRemote
            case (false, .none): L10n.Config.stateDefault
            }
        }
    }

    public private(set) var entries: [Entry] = []
    public private(set) var toast: String?
    public private(set) var isRefreshing = false

    private let settings: DebugSettings
    private let remoteConfig: any RemoteConfigService
    private let json: any JSONTextFormatting
    private let router: Router

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    /// - Parameter remoteConfig: сам источник, без подмен поверх: экран
    ///   показывает, что реально приехало с сервера, и подмену рядом с ним.
    public convenience init(
        settings: DebugSettings,
        remoteConfig: any RemoteConfigService,
        router: Router
    ) {
        self.init(settings: settings, remoteConfig: remoteConfig, json: JSONText(), router: router)
    }

    init(
        settings: DebugSettings,
        remoteConfig: any RemoteConfigService,
        json: any JSONTextFormatting,
        router: Router
    ) {
        self.settings = settings
        self.remoteConfig = remoteConfig
        self.json = json
        self.router = router
        reload()
    }

    public var hasOverrides: Bool {
        !settings.remoteConfigOverrides.isEmpty
    }

    /// Правка живёт на своём экране: в конфиге лежат объекты, а их
    /// не набрать в поле алерта.
    public func open(_ entry: Entry) {
        router.push(DebugRoute.remoteConfigValue(name: entry.id))
    }

    public func resetAll() {
        settings.clearRemoteConfigOverrides()
        reload()
        say(L10n.Config.allCleared)
    }

    /// Значения тянутся заново прямо с сервера: в отладочной сборке кэш
    /// у SDK отключён, поэтому правку в веб-консоли видно сразу.
    public func refresh() async {
        isRefreshing = true
        await remoteConfig.refresh()
        isRefreshing = false
        reload()
        say(
            entries.isEmpty
                ? L10n.Config.nothingFetched
                : L10n.Config.updated
        )
    }

    public func goBack() {
        router.pop()
    }

    /// Список перечитывают и на возврате с экрана значения: подмену там
    /// ставят и снимают, а строка о ней рассказывает.
    public func reload() {
        let overrides = settings.remoteConfigOverrides
        entries = Set(remoteConfig.names + overrides.names).sorted().map { name in
            let remoteText = remoteConfig.text(for: name)

            return Entry(
                id: name,
                remoteText: remoteText,
                overrideText: overrides[name],
                prettyValue: (overrides[name] ?? remoteText).flatMap { json.pretty($0) }
            )
        }
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
