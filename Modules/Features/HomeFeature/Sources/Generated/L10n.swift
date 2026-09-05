// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Greeting {
        /// Good afternoon
        static var afternoon: String {
            tr("greeting.afternoon")
        }

        /// Good evening
        static var evening: String {
            tr("greeting.evening")
        }

        /// Good morning
        static var morning: String {
            tr("greeting.morning")
        }

        /// Good night
        static var night: String {
            tr("greeting.night")
        }
    }

    enum Home {
        /// Profile
        static var profile: String {
            tr("home.profile")
        }

        /// Where do we start?
        static var prompt: String {
            tr("home.prompt")
        }
    }
}

/// Один вход за переводом на весь модуль.
///
/// `locale` обязателен: без него `String(format:)` выбирает форму слова
/// по правилам английского, и русское «5 файлов» превращается в «5 файла».
private func tr(_ key: String, _ arguments: CVarArg...) -> String {
    let format = L10nBundle.localizedString(forKey: key, in: .module)
    guard !arguments.isEmpty else { return format }

    return String(format: format, locale: L10nBundle.locale, arguments: arguments)
}
