import Foundation

/// Ключ значения: имя в хранилище плюс тип, который по этому имени лежит.
///
/// Тип держит ключ, а не место вызова: положить по `onboardingTourSeen`
/// строку или прочитать оттуда число не выйдет — не соберётся.
///
/// Объявляется ключ рядом с тем, кто им владеет, расширением по типу
/// значения:
/// ```swift
/// public extension StorageKey where Value == Bool {
///     static var onboardingTourSeen: StorageKey { StorageKey("slimly.onboarding.tourSeen") }
/// }
/// ```
public struct StorageKey<Value: StorageValue>: Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}
