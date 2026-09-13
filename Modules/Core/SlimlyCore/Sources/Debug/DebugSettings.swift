import Foundation
import Observation

/// Отказ, который отладочное меню подставляет вместо настоящей обработки.
///
/// Экран итога умеет показывать список отказов, но дождаться настоящего сбоя
/// от системы почти невозможно: место кончается редко, iCloud выгружает файл
/// быстро. Подмена — единственный способ увидеть этот список глазами.
public enum SimulatedFailure: String, CaseIterable, Identifiable, Sendable {
    case off
    case noSpace
    case unreadable
    case interrupted
    case saveDenied

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .off: L10n.Failure.none
        case .noSpace: L10n.Failure.noSpace
        case .unreadable: L10n.Failure.unreadable
        case .interrupted: L10n.Failure.interrupted
        case .saveDenied: L10n.Failure.saveDenied
        }
    }

    /// Причина отказа. Текст попадает в список итога рядом с файлом, поэтому
    /// написан для пользователя, а не для лога.
    public var reason: String? {
        switch self {
        case .off: nil
        case .noSpace: L10n.FailureDetail.noSpace
        case .unreadable: L10n.FailureDetail.unreadable
        case .interrupted: L10n.FailureDetail.interrupted
        case .saveDenied: L10n.FailureDetail.saveDenied
        }
    }
}

extension SimulatedFailure: StorageValue { }

public extension StorageKey where Value == SimulatedFailure {
    static var simulatedFailure: StorageKey { StorageKey("slimly.debug.simulatedFailure") }
}

/// Состояние отладочного меню: что именно сборка сейчас подменяет.
///
/// Переживает перезапуск, потому что проверяют обычно не один экран, а путь
/// до него: перещёлкивать тумблер после каждого запуска — верный способ
/// проверить не то.
@MainActor
@Observable
public final class DebugSettings {
    public private(set) var simulatedFailure: SimulatedFailure

    /// Подменённые значения удалённого конфига. Читает их сам конфиг прямо
    /// из хранилища, а здесь они лежат ради экрана: ему нужно и показать
    /// подмену рядом с настоящим значением, и знать, что она вообще есть.
    public private(set) var remoteConfigOverrides: RemoteConfigOverrides

    /// Включена ли подписка. Тумблер ставит тот же тариф, что и покупка:
    /// пределы у Pro свои, и увидеть их надо на настоящих экранах, а не
    /// только в объекте конфига. Держать своё поле рядом нельзя — источник
    /// тарифа один на всё приложение, и меню читает его же.
    public var isPro: Bool { pro.isActive }

    private let storage: any KeyValueStorage
    private let pro: StoredProSubscription

    public init(storage: any KeyValueStorage = DefaultsStorage(), pro: StoredProSubscription) {
        self.storage = storage
        self.pro = pro
        simulatedFailure = storage.value(for: .simulatedFailure, default: .off)
        remoteConfigOverrides = storage.value(for: .remoteConfigOverrides, default: RemoteConfigOverrides())
    }

    /// Хоть одна подмена включена. Пока это так, поверх экранов горит метка
    /// DEBUG: странное поведение сборки должно объясняться раньше, чем его
    /// пойдут искать в коде.
    public var isOverridden: Bool {
        simulatedFailure != .off || !remoteConfigOverrides.isEmpty || isPro
    }

    public func setPro(_ active: Bool) {
        pro.update(isActive: active)
    }

    public func setSimulatedFailure(_ failure: SimulatedFailure) {
        simulatedFailure = failure
        storage.set(failure, for: .simulatedFailure)
    }

    /// Пустой текст — это не значение, а «подмены нет»: разбор пустой строки
    /// всё равно провалился бы, и ключ получил бы своё умолчание вместо того,
    /// что пришло с сервера.
    public func setRemoteConfigOverride(_ text: String?, for name: String) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteConfigOverrides[name] = trimmed?.isEmpty == false ? trimmed : nil
        storage.set(remoteConfigOverrides, for: .remoteConfigOverrides)
    }

    public func clearRemoteConfigOverrides() {
        remoteConfigOverrides = RemoteConfigOverrides()
        storage.set(remoteConfigOverrides, for: .remoteConfigOverrides)
    }

    public func reset() {
        setSimulatedFailure(.off)
        setPro(false)
        clearRemoteConfigOverrides()
    }
}
