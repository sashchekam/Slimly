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

        /// Действующее значение — то, что получит владелец ключа.
        /// Прочерк значит «источник промолчал»: в дело пойдёт умолчание
        /// самого ключа, а его знает только объявивший ключ код.
        public var value: String { overrideText ?? remoteText ?? "—" }

        public var source: String {
            switch (isOverridden, remoteText) {
            case (true, .some):
                L10n.Config.stateOverridden(remoteText ?? "")
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

    /// Имя ключа, который правят прямо сейчас. Ввод идёт в системном алерте:
    /// поле ввода в приложении больше нигде не нужно, и заводить под него
    /// свой контрол ради служебного экрана незачем.
    public private(set) var editedName: String?

    public var draft = ""

    private let settings: DebugSettings
    private let remoteConfig: any RemoteConfigService
    private let router: Router

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    /// - Parameter remoteConfig: сам источник, без подмен поверх: экран
    ///   показывает, что реально приехало с сервера, и подмену рядом с ним.
    public init(
        settings: DebugSettings,
        remoteConfig: any RemoteConfigService,
        router: Router
    ) {
        self.settings = settings
        self.remoteConfig = remoteConfig
        self.router = router
        reload()
    }

    public var hasOverrides: Bool {
        !settings.remoteConfigOverrides.isEmpty
    }

    /// Алерт правки. Закрыть его может и система — по нажатию мимо кнопок,
    /// поэтому закрытие снимает правку, а не только кнопка «Отмена».
    public var isEditing: Bool {
        get { editedName != nil }
        set {
            guard !newValue else { return }
            editedName = nil
        }
    }

    public var editedTitle: String {
        editedName ?? ""
    }

    /// У неподменённого ключа снимать нечего — кнопки в алерте быть не должно.
    public var canResetEdit: Bool {
        guard let editedName else { return false }

        return settings.remoteConfigOverrides[editedName] != nil
    }

    public func edit(_ entry: Entry) {
        editedName = entry.id
        draft = entry.overrideText ?? entry.remoteText ?? ""
    }

    public func applyEdit() {
        guard let editedName else { return }
        settings.setRemoteConfigOverride(draft, for: editedName)
        self.editedName = nil
        reload()
        say(
            settings.remoteConfigOverrides[editedName] == nil
                ? L10n.Config.overrideCleared
                : L10n.Config.overrideSet
        )
    }

    public func resetEdit() {
        guard let editedName else { return }
        settings.setRemoteConfigOverride(nil, for: editedName)
        self.editedName = nil
        reload()
        say(L10n.Config.overrideCleared)
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

    private func reload() {
        let overrides = settings.remoteConfigOverrides
        entries = Set(remoteConfig.names + overrides.names).sorted().map { name in
            Entry(
                id: name,
                remoteText: remoteConfig.text(for: name),
                overrideText: overrides[name]
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
