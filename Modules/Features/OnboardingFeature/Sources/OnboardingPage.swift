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
    static let tour: [OnboardingPage] = [
        OnboardingPage(
            illustration: .compress,
            kicker: "Сжатие",
            title: "Освободите место, не удаляя ничего",
            text: "Выберите фото и видео, задайте уровень — покажем размер до и после "
                + "и сравнение кадров. Оригиналы остаются, пока вы сами не удалите их."
        ),
        OnboardingPage(
            illustration: .convert,
            kicker: "Конвертация",
            title: "Любой формат — под любую задачу",
            text: "HEIC, JPEG, PNG, H.264, HEVC — сразу для всей пачки, "
                + "с сохранением даты съёмки и геометки."
        ),
        OnboardingPage(
            illustration: .audio,
            kicker: "Звук",
            title: "Достаньте звук из видео",
            text: "Лекция, интервью, голосовое из видео — сохраняем в M4A или WAV "
                + "без перекодирования лишнего."
        ),
        OnboardingPage(
            illustration: .scan,
            kicker: "Скан",
            title: "Документ в PDF за одну съёмку",
            text: "Снимите страницы подряд: границы найдутся сами, кадр выпрямится, "
                + "всё соберётся в один PDF."
        ),
    ]
}
