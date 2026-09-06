// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Accessibility {
        /// Back
        static var back: String {
            tr("accessibility.back")
        }

        /// Before and after comparison
        static var compare: String {
            tr("accessibility.compare")
        }

        /// Compression level
        static var compressionLevel: String {
            tr("accessibility.compressionLevel")
        }

        /// Loading
        static var loading: String {
            tr("accessibility.loading")
        }
    }

    enum Common {
        /// Cancel
        static var cancel: String {
            tr("common.cancel")
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
