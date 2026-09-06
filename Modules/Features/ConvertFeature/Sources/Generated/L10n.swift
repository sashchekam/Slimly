// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Common {
        /// Convert
        static var action: String {
            tr("common.action")
        }
    }

    enum Photo {
        /// The format comes on the next step
        static var hint: String {
            tr("photo.hint")
        }

        /// Photo conversion
        static var title: String {
            tr("photo.title")
        }
    }

    enum PhotoFormat {
        /// HEIC is lighter, JPEG works everywhere. PNG is lossless but heavier than the original. The
        /// source format is not listed.
        static var note: String {
            tr("photoFormat.note")
        }

        /// Photo
        static var source: String {
            tr("photoFormat.source")
        }

        /// Which format
        static var title: String {
            tr("photoFormat.title")
        }
    }

    enum Video {
        /// Container and codec on the next step
        static var hint: String {
            tr("video.hint")
        }

        /// Video conversion
        static var title: String {
            tr("video.title")
        }
    }

    enum VideoFormat {
        /// This is re-encoding, not a renamed extension.
        static var note: String {
            tr("videoFormat.note")
        }

        /// Video
        static var source: String {
            tr("videoFormat.source")
        }

        /// Container and codec
        static var title: String {
            tr("videoFormat.title")
        }
    }

    enum VideoNote {
        /// Apple’s container: handy for iMovie and Final Cut. Weighs like HEVC in MP4, but opens worse
        /// on Windows and Android.
        static var movHevc: String {
            tr("videoNote.movHevc")
        }

        /// Opens everywhere: phones, TVs, editors, old players. At the same quality it weighs more than
        /// HEVC.
        static var mp4H264: String {
            tr("videoNote.mp4H264")
        }

        /// The same MP4, about half the weight at the same quality. Devices older than 2015 may not
        /// play it.
        static var mp4Hevc: String {
            tr("videoNote.mp4Hevc")
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
