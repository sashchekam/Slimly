import Foundation

/// Системный список языков — то, по чему система выбирает перевод при запуске.
///
/// Живёт отдельно от хранилища выбора: это не наше значение, а чужое,
/// и работы с ним ровно две — прочитать, что система выдала приложению,
/// и положить поверх наше переопределение.
public protocol SystemLanguage: Sendable {
    /// Язык, на котором система разговаривает с приложением сейчас.
    ///
    /// Пока переопределения нет, это и есть язык телефона. После него система
    /// показывает приложению его собственный выбор — и язык телефона
    /// приложению больше не виден, спросить его неоткуда.
    var resolvedIdentifier: String { get }

    /// Переопределение языка для нашего приложения. `nil` снимает его,
    /// и приложение снова идёт за телефоном.
    func setOverride(_ code: String?)
}

/// Список `AppleLanguages` в `UserDefaults`.
///
/// `@unchecked` — по той же причине, что и у ``DefaultsStorage``: `UserDefaults`
/// потокобезопасен по контракту, но `Sendable` в SDK не помечен.
public struct DefaultsSystemLanguage: SystemLanguage, @unchecked Sendable {
    /// Ключ системный, а не наш: под этим именем список читает и пишет сама
    /// iOS — в том числе когда язык приложения меняют в её настройках.
    private static let key = "AppleLanguages"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var resolvedIdentifier: String {
        Locale.preferredLanguages.first ?? AppLanguage.english.code
    }

    public func setOverride(_ code: String?) {
        if let code {
            defaults.set([code], forKey: Self.key)
        } else {
            defaults.removeObject(forKey: Self.key)
        }
    }
}
