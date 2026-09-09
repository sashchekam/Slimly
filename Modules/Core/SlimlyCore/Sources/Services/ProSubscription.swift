import Foundation

/// Есть ли у пользователя Slimly Pro.
///
/// Покупок в приложении пока нет, и включить подписку по-настоящему нечем.
/// Флаг всё равно живёт за протоколом: пределы тарифов уже разъехались,
/// и когда покупки появятся, меняться будет одна реализация, а не каждый
/// инструмент, который спрашивает свой предел.
public protocol ProSubscription: Sendable {
    var isActive: Bool { get }
}

public extension StorageKey where Value == Bool {
    static var proSubscription: StorageKey { StorageKey("slimly.pro.active") }
}

/// Подписки нет. Так собран релиз, пока покупок не существует: сказать «Pro»
/// в нём некому, и тариф у всех бесплатный.
public struct NoProSubscription: ProSubscription {
    public init() { }

    public var isActive: Bool { false }
}

/// Подписка, включённая руками из отладочного меню.
///
/// Значение берётся из хранилища на каждом обращении, а не кладётся в поле:
/// переключают его с главного потока, а спрашивают откуда угодно — общее
/// изменяемое поле пришлось бы держать под замком ради пары чтений за экран.
/// Так же устроены и подмены конфига.
public struct StoredProSubscription: ProSubscription {
    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
    }

    public var isActive: Bool {
        storage.value(for: .proSubscription, default: false)
    }
}
