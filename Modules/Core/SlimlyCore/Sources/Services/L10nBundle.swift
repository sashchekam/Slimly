import Foundation

/// Бандл, из которого модуль берёт перевод.
///
/// Через него ходит весь сгенерированный `L10n`, и ради этого он и заведён:
/// `String(localized:)` игнорирует переданную локаль и берёт язык, который
/// система выбрала при запуске, — сменить его до следующего запуска нечем.
/// `Bundle.localizedString(forKey:value:table:)` такого выбора не делает:
/// язык решает тот, кто дал бандл, поэтому строки разворачиваются на новый
/// язык сразу.
///
/// Не сервис за протоколом, а глобальное значение — по той же причине, что
/// и `Bundle.module`: у строки нет места, куда передать зависимость. Экраны
/// и форматтеры зовут `L10n` из тела, а не получают его в конструкторе.
public enum L10nBundle {
    private static let state = State()

    /// Язык, на котором показывать строки. `nil` — тот, что выбрала система.
    ///
    /// При запуске здесь `nil`, и это не заглушка: ручной выбор лежит
    /// в `AppleLanguages`, и система уже отдала приложению нужные переводы.
    /// Значение появляется, когда язык меняют на ходу, — до перезапуска
    /// система про этот выбор ещё не знает.
    public static var language: AppLanguage? {
        get { state.language }
        set { state.setLanguage(newValue) }
    }

    /// Локаль выбранного языка — её ждёт `String(format:)`.
    ///
    /// Без неё форма слова выбирается по правилам английского: русское
    /// «5 файлов» превращается в «5 файла».
    public static var locale: Locale {
        guard let language = state.language else { return .current }
        return Locale(identifier: language.code)
    }

    /// Перевод строки из бандла модуля.
    ///
    /// Значение по умолчанию — сам ключ: пропущенный перевод так видно
    /// на экране, а не молча заменено пустотой.
    public static func localizedString(forKey key: String, in bundle: Bundle) -> String {
        state.translations(in: bundle).localizedString(forKey: key, value: key, table: nil)
    }
}

/// Выбранный язык и найденные под него бандлы переводов.
///
/// `@unchecked` — по той же причине, что и у ``DefaultsStorage``: за
/// одновременный доступ отвечает замок, а `Sendable` сложить из `Bundle`
/// и перечисления компилятор не может.
private final class State: @unchecked Sendable {
    private let lock = NSLock()
    private var current: AppLanguage?
    /// Найденный `.lproj` для каждого модульного бандла. Поиск идёт по диску,
    /// а строку просят на каждой перерисовке экрана.
    private var cache: [ObjectIdentifier: Bundle] = [:]

    var language: AppLanguage? {
        lock.withLock { current }
    }

    func setLanguage(_ language: AppLanguage?) {
        lock.withLock {
            current = language
            cache = [:]
        }
    }

    /// Бандл с переводами внутри модульного.
    ///
    /// Пока язык не выбран вручную, это сам модульный бандл: систему тогда
    /// не надо поправлять — она уже выбрала перевод при запуске.
    func translations(in bundle: Bundle) -> Bundle {
        lock.withLock {
            guard let language = current else { return bundle }

            let identifier = ObjectIdentifier(bundle)
            if let found = cache[identifier] { return found }

            let found = Self.translations(for: language, in: bundle) ?? bundle
            cache[identifier] = found
            return found
        }
    }

    /// Папка перевода под язык: сначала точное совпадение («pt-BR»), потом
    /// язык без региона, потом английский — на нём есть каждая строка.
    private static func translations(for language: AppLanguage, in bundle: Bundle) -> Bundle? {
        let base = language.code.split(separator: "-").first.map(String.init)

        for code in [language.code, base, AppLanguage.english.code] {
            guard
                let code,
                let path = bundle.path(forResource: code, ofType: "lproj"),
                let found = Bundle(path: path)
            else { continue }
            return found
        }

        return nil
    }
}
