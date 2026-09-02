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
        case .off: "Нет"
        case .noSpace: "Нет места"
        case .unreadable: "Битый файл"
        case .interrupted: "Свернули"
        case .saveDenied: "Запись запрещена"
        }
    }

    /// Причина отказа. Текст попадает в список итога рядом с файлом, поэтому
    /// написан для пользователя, а не для лога.
    public var reason: String? {
        switch self {
        case .off: nil
        case .noSpace: "На устройстве не хватило места для копии"
        case .unreadable: "Файл повреждён или ещё выгружается из iCloud"
        case .interrupted: "Обработка прервана системой"
        case .saveDenied: "iOS не дала сохранить результат в медиатеку"
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

    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
        simulatedFailure = storage.value(for: .simulatedFailure, default: .off)
    }

    /// Хоть одна подмена включена. Пока это так, поверх экранов горит метка
    /// DEBUG: странное поведение сборки должно объясняться раньше, чем его
    /// пойдут искать в коде.
    public var isOverridden: Bool {
        simulatedFailure != .off
    }

    public func setSimulatedFailure(_ failure: SimulatedFailure) {
        simulatedFailure = failure
        storage.set(failure, for: .simulatedFailure)
    }

    public func reset() {
        setSimulatedFailure(.off)
    }
}
