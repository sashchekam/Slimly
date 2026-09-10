import Foundation

/// Пора ли просить оценку в App Store.
///
/// Само окно рисует система, и решать, показывать его или нет, она будет
/// сама. Но спрашивать её в каждом удачном сохранении незачем: момент
/// выбираем мы, и выбор этот — не часть экрана итога, а отдельное правило.
/// Поэтому оно живёт за протоколом: в отладочной сборке его подменяют,
/// а экран знает только «сейчас» или «не сейчас».
public protocol ReviewPrompting: Sendable {
    /// Файлы сохранены — самый удачный момент за весь флоу.
    ///
    /// Сохранения считает он же: счётчик — часть правила, и держать его
    /// на экране значило бы разложить одно решение по двум местам.
    func shouldAskAfterSave() -> Bool

    /// Окно показано: отсчёт паузы начинается заново.
    func didAsk()
}

public extension StorageKey where Value == Int {
    static var reviewSaveCount: StorageKey { StorageKey("slimly.review.saveCount") }
}

public extension StorageKey where Value == Double {
    /// Когда просили в прошлый раз — секундами с 1970: `Date` хранилище
    /// не умеет, а сравнивать даты и так приходится числами.
    static var reviewAskedAt: StorageKey { StorageKey("slimly.review.askedAt") }
}

/// Правило по умолчанию: просим после третьего удачного сохранения
/// и не чаще раза в 90 дней.
///
/// Третьего, а не первого: первый результат ещё ничего не говорит о том,
/// прижилось ли приложение, — просьба в этот момент попадает в человека,
/// который сам не знает ответа. Пауза же одна на все исходы: оценил
/// человек, закрыл окно или система не показала его вовсе — нам об этом
/// не сообщают, и «уже оценил» проверить нечем.
public struct StoredReviewPrompt: ReviewPrompting {
    private let storage: any KeyValueStorage
    private let savesBeforeAsking: Int
    private let cooldown: TimeInterval

    public init(
        storage: any KeyValueStorage = DefaultsStorage(),
        savesBeforeAsking: Int = 3,
        cooldown: TimeInterval = 90 * 24 * 60 * 60
    ) {
        self.storage = storage
        self.savesBeforeAsking = savesBeforeAsking
        self.cooldown = cooldown
    }

    public func shouldAskAfterSave() -> Bool {
        let saves = storage.value(for: .reviewSaveCount, default: 0) + 1
        storage.set(saves, for: .reviewSaveCount)

        guard saves >= savesBeforeAsking else { return false }
        guard let asked = storage.value(for: .reviewAskedAt) else { return true }

        return Date().timeIntervalSince1970 - asked >= cooldown
    }

    public func didAsk() {
        storage.set(Date().timeIntervalSince1970, for: .reviewAskedAt)
    }
}

/// Оценку не просим никогда. Так собраны превью и тесты: окно системы
/// поверх экрана там только мешает, а счётчик в `UserDefaults` — лишний след.
public struct NoReviewPrompt: ReviewPrompting {
    public init() { }

    public func shouldAskAfterSave() -> Bool { false }

    public func didAsk() { }
}
