// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Format {
        /// M4A is native to iOS, WAV is lossless but heavy. The video stays as it is.
        static var note: String {
            tr("format.note")
        }

        /// Video track
        static var source: String {
            tr("format.source")
        }

        /// Track format
        static var title: String {
            tr("format.title")
        }
    }

    enum Picker {
        /// The track becomes a separate file
        static var hint: String {
            tr("picker.hint")
        }
    }

    enum Preview {
        /// Done
        static var close: String {
            tr("preview.close")
        }

        /// The track is unavailable
        static var unavailable: String {
            tr("preview.unavailable")
        }
    }

    enum Tool {
        /// Extract audio
        static var extractAudio: String {
            tr("tool.extractAudio")
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
