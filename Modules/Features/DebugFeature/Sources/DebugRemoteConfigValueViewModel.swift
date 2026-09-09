import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Одно значение конфига целиком: что лежит на сервере, чем это подменено
/// на устройстве и текст, который правят.
///
/// Отдельный экран, а не поле в алерте: в конфиге лежат объекты, и набирают
/// их по строкам — с отступами, с оглядкой на серверное значение рядом.
@MainActor
@Observable
public final class DebugRemoteConfigValueViewModel {
    /// Имя ключа — заголовок экрана и адрес подмены.
    public let name: String

    /// Текст, который правят. Объект открывается разложенным по строкам:
    /// как приехал — одной строкой — его не прочитать и не поправить.
    public var draft: String

    public let remoteText: String?

    private let settings: DebugSettings
    private let json: any JSONTextFormatting
    private let router: Router

    /// - Parameter remoteConfig: источник без подмен поверх: экран
    ///   показывает серверное значение рядом с тем, что набрали.
    public convenience init(
        name: String,
        settings: DebugSettings,
        remoteConfig: any RemoteConfigService,
        router: Router
    ) {
        self.init(name: name, settings: settings, remoteConfig: remoteConfig, json: JSONText(), router: router)
    }

    init(
        name: String,
        settings: DebugSettings,
        remoteConfig: any RemoteConfigService,
        json: any JSONTextFormatting,
        router: Router
    ) {
        self.name = name
        self.settings = settings
        self.json = json
        self.router = router
        remoteText = remoteConfig.text(for: name)

        let current = settings.remoteConfigOverrides[name] ?? remoteText ?? ""
        draft = json.pretty(current) ?? current
    }

    public var isOverridden: Bool {
        settings.remoteConfigOverrides[name] != nil
    }

    public var status: String {
        switch (isOverridden, remoteText) {
        // Серверное значение в подписи не разворачиваем: оно и так лежит
        // на этом экране целиком, ниже поля.
        case (true, .some): L10n.Config.stateOverriddenShort
        case (true, .none): L10n.Config.stateOverriddenOnly
        case (false, .some): L10n.Config.stateRemote
        case (false, .none): L10n.Config.stateDefault
        }
    }

    /// Серверное значение показываем, только пока поверх него лежит подмена:
    /// без подмены оно и есть содержимое поля, и второй раз ему взяться
    /// на экране неоткуда.
    public var remotePretty: String? {
        guard isOverridden, let remoteText else { return nil }

        return json.pretty(remoteText) ?? remoteText
    }

    /// Набранный объект не разобрался. Сохранять такое нельзя: экран, который
    /// его прочитает, молча возьмёт умолчание, и причину придётся искать
    /// уже в поведении инструмента, а не здесь.
    public var isValid: Bool {
        !json.looksLikeObject(draft) || json.pretty(draft) != nil
    }

    /// Раскладывать нечего, если это не объект или он уже разложен.
    public var canFormat: Bool {
        guard let pretty = json.pretty(draft) else { return false }

        return pretty != draft
    }

    public func format() {
        guard let pretty = json.pretty(draft) else { return }

        draft = pretty
    }

    /// Объект уходит в подмену разложенным: править его потом будут здесь же,
    /// а разбору лишние пробелы и переносы не мешают. Пустое поле снимает
    /// подмену — этим занимается само хранилище настроек.
    public func apply() {
        guard isValid else { return }

        settings.setRemoteConfigOverride(json.pretty(draft) ?? draft, for: name)
        router.pop()
    }

    public func restore() {
        settings.setRemoteConfigOverride(nil, for: name)
        router.pop()
    }

    public func goBack() {
        router.pop()
    }
}
