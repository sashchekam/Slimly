import Foundation

/// Показывали ли уже вводный тур.
///
/// Решение «с чего начать приложение» принимает старт, а отметку о показе
/// ставит последний шаг тура — поэтому флаг вынесен из обоих и живёт
/// за протоколом: подставив другую реализацию, тур можно гонять
/// сколько угодно раз, не трогая хранилище устройства.
public protocol OnboardingState: Sendable {
    var hasSeenTour: Bool { get }

    func markTourSeen()
}

/// Отметка в `UserDefaults`: тур показывается один раз за установку.
///
/// `@unchecked` — потому что `UserDefaults` потокобезопасен по контракту,
/// но `Sendable` в SDK не помечен.
public struct DefaultsOnboardingState: OnboardingState, @unchecked Sendable {
    private static let key = "slimly.onboarding.tourSeen"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var hasSeenTour: Bool {
        defaults.bool(forKey: Self.key)
    }

    public func markTourSeen() {
        defaults.set(true, forKey: Self.key)
    }
}
