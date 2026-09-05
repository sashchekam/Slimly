// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Level {
        /// Compress · %@
        static func action(_ p1: String) -> String {
            tr("level.action", p1)
        }

        /// Minus %@ · estimated from bitrate, exact number after processing
        static func estimate(_ p1: String) -> String {
            tr("level.estimate", p1)
        }

        /// Compression level
        static var title: String {
            tr("level.title")
        }
    }

    enum Picker {
        /// Photos and videos from your library
        static var hint: String {
            tr("picker.hint")
        }

        /// Pick files
        static var title: String {
            tr("picker.title")
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
