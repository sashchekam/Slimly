import Foundation

/// Язык, на котором приложение умеет говорить.
///
/// Список закрытый и повторяет переводы в строковых каталогах: язык
/// появляется в нём только вместе со строками, поэтому здесь перечисление,
/// а не код строкой откуда угодно.
public enum AppLanguage: String, CaseIterable, Sendable, Identifiable {
    case german = "de"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case portugueseBrazil = "pt-BR"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"

    public var id: String { rawValue }

    /// Код языка — он же имя папки перевода в бандле.
    public var code: String { rawValue }

    /// Название на самом языке: «Deutsch», «日本語». Его читает тот, кто ищет
    /// в списке свой язык, — и прочесть он должен на своём.
    public var nativeName: String {
        Self.nativeName(of: code)
    }

    /// Название на языке интерфейса: «Немецкий» подписью под «Deutsch».
    ///
    /// Спрашиваем систему, а не держим свою таблицу: иначе десять названий
    /// пришлось бы перевести на десять языков и сверять при каждой правке
    /// списка.
    public func name(in locale: Locale) -> String {
        Self.name(of: code, in: locale)
    }

    /// Ближайший наш язык к тому, что стоит в телефоне.
    ///
    /// Сначала точное совпадение, потом язык без региона: «en-US» — это
    /// английский, а «pt-PT» уже не наш «pt-BR», и такому телефону приложение
    /// ответит по-английски.
    public static func closest(to identifier: String) -> AppLanguage? {
        if let exact = AppLanguage(rawValue: identifier) { return exact }

        let base = identifier.split(separator: "-").first.map(String.init) ?? identifier
        return AppLanguage(rawValue: base)
    }

    /// Название языка на нём самом — в том числе языка, которого у нас нет:
    /// строку «как в телефоне» подписывают и таким.
    public static func nativeName(of identifier: String) -> String {
        name(of: identifier, in: Locale(identifier: identifier))
    }

    /// Система отдаёт названия строчными («немецкий»), а в списке они стоят
    /// заголовками строк — поэтому первая буква поднимается, и по правилам
    /// того же языка: в турецком у «i» заглавная не та.
    private static func name(of identifier: String, in locale: Locale) -> String {
        guard let name = locale.localizedString(forIdentifier: identifier) else { return identifier }

        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }
}
