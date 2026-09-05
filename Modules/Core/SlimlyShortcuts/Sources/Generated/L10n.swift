// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Audio {
        /// Audio
        static var short: String {
            tr("audio.short")
        }

        /// M4A or WAV from video
        static var subtitle: String {
            tr("audio.subtitle")
        }

        /// Extract audio
        static var title: String {
            tr("audio.title")
        }
    }

    enum Compress {
        /// Photos and videos
        static var subtitle: String {
            tr("compress.subtitle")
        }

        /// Compression
        static var title: String {
            tr("compress.title")
        }
    }

    enum Photo {
        /// Photos
        static var short: String {
            tr("photo.short")
        }

        /// Photo conversion
        static var title: String {
            tr("photo.title")
        }
    }

    enum Scan {
        /// Scan
        static var short: String {
            tr("scan.short")
        }

        /// Photos or camera → PDF
        static var subtitle: String {
            tr("scan.subtitle")
        }

        /// Document scan
        static var title: String {
            tr("scan.title")
        }
    }

    enum Video {
        /// Videos
        static var short: String {
            tr("video.short")
        }

        /// Video conversion
        static var title: String {
            tr("video.title")
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
