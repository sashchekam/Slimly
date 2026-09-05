/// Шаг вводного тура: кикер, заголовок, текст и иллюстрация к ним.
///
/// Шаги — это содержание самого тура, а не состав приложения: они ничего
/// не открывают и ни на какую фичу не ссылаются, поэтому лежат здесь,
/// а не приходят из App, как плитки главного экрана.
public struct OnboardingPage: Identifiable, Sendable {
    /// Что показывает картинка над текстом. Иллюстрации разные не только
    /// содержанием, но и раскладкой, поэтому это тип, а не имя ассета.
    public enum Illustration: Sendable {
        case compress
        case convert
        case audio
        case scan
    }

    public let illustration: Illustration
    public let kicker: String
    public let title: String
    public let text: String

    public var id: String { title }
}

public extension OnboardingPage {
    /// Порядок шагов повторяет порядок инструментов на главной: первым идёт
    /// то, ради чего приложение ставят, последним — самый узкий сценарий.
    static var tour: [OnboardingPage] {
        [
            OnboardingPage(
                illustration: .compress,
                kicker: L10n.Compress.kicker,
                title: L10n.Compress.title,
                text: L10n.Compress.text
            ),
            OnboardingPage(
                illustration: .convert,
                kicker: L10n.Convert.kicker,
                title: L10n.Convert.title,
                text: L10n.Convert.text
            ),
            OnboardingPage(
                illustration: .audio,
                kicker: L10n.Audio.kicker,
                title: L10n.Audio.title,
                text: L10n.Audio.text
            ),
            OnboardingPage(
                illustration: .scan,
                kicker: L10n.Scan.kicker,
                title: L10n.Scan.title,
                text: L10n.Scan.text
            ),
        ]
    }
}
