import Foundation
import Observation

/// Есть ли у пользователя Slimly Pro.
///
/// Флаг живёт за протоколом, потому что источников у него два: ответ магазина
/// в обычной сборке и тумблер отладочного меню в отладочной. Пределы тарифов
/// спрашивают именно его, а не магазин: инструмент не должен знать, что
/// подписка вообще откуда-то приезжает.
///
/// Живёт на главной очереди: тариф — это состояние приложения, за ним
/// наблюдают экраны и перерисовываются, когда покупка прошла.
@MainActor
public protocol ProSubscription: Sendable {
    var isActive: Bool { get }
}

public extension StorageKey where Value == Bool {
    static var proSubscription: StorageKey { StorageKey("slimly.pro.active") }
}

/// Подписки нет и взяться ей неоткуда. Умолчание там, где тариф не важен:
/// превью, тесты и сборка без магазина.
public struct NoProSubscription: ProSubscription {
    public init() { }

    public var isActive: Bool { false }
}

/// Тариф, каким его запомнило устройство.
///
/// Значение лежит полем, а не читается из хранилища на каждом обращении:
/// за ним наблюдают вью, а `UserDefaults` SwiftUI не наблюдает. В хранилище
/// оно всё равно уходит — следующий запуск должен знать про подписку
/// до того, как ответит магазин, иначе Pro на секунду «пропадает».
@MainActor
@Observable
public final class StoredProSubscription: ProSubscription {
    public private(set) var isActive: Bool

    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
        isActive = storage.value(for: .proSubscription, default: false)
    }

    /// Ответ магазина или тумблер отладочного меню — источник тут один
    /// на двоих, и подмена в меню действует ровно так же, как настоящая
    /// покупка: до следующего ответа магазина.
    public func update(isActive: Bool) {
        guard self.isActive != isActive else { return }

        self.isActive = isActive
        storage.set(isActive, for: .proSubscription)
    }
}
