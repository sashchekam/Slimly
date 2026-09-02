import Foundation

/// Показывали ли уже вводный тур.
///
/// Решение «с чего начать приложение» принимает старт, а отметку о показе
/// ставит последний шаг тура — поэтому флаг вынесен из обоих и живёт
/// за протоколом: подставив другую реализацию, тур можно гонять
/// сколько угодно раз, не трогая хранилище устройства.
public protocol OnboardingState: Sendable {
    var hasSeenTour: Bool { get }

    /// Отметку умеет и снимать: отладочному меню нужно вернуть сборку
    /// в состояние первого запуска, а не только отметить показ.
    func setTourSeen(_ seen: Bool)
}

public extension OnboardingState {
    func markTourSeen() {
        setTourSeen(true)
    }
}

public extension StorageKey where Value == Bool {
    static var onboardingTourSeen: StorageKey { StorageKey("slimly.onboarding.tourSeen") }
}

/// Отметка в хранилище: тур показывается один раз за установку.
public struct StoredOnboardingState: OnboardingState {
    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
    }

    public var hasSeenTour: Bool {
        storage.value(for: .onboardingTourSeen, default: false)
    }

    public func setTourSeen(_ seen: Bool) {
        storage.set(seen, for: .onboardingTourSeen)
    }
}
