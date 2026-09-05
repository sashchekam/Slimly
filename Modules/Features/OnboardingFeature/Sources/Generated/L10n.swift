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
        static var kicker: String {
            tr("audio.kicker")
        }

        /// M4A · 4.2 MB
        static var sample: String {
            tr("audio.sample")
        }

        /// A lecture, an interview, a voice note inside a video — we save it as M4A or WAV without
        /// re-encoding anything extra.
        static var text: String {
            tr("audio.text")
        }

        /// Pull the audio out of a video
        static var title: String {
            tr("audio.title")
        }
    }

    enum Compress {
        /// Compression
        static var kicker: String {
            tr("compress.kicker")
        }

        /// 1.4 GB → 590 MB
        static var sample: String {
            tr("compress.sample")
        }

        /// Pick photos and videos, set the level — we show the size before and after and a frame
        /// comparison. The originals stay until you delete them.
        static var text: String {
            tr("compress.text")
        }

        /// Free up space without deleting anything
        static var title: String {
            tr("compress.title")
        }
    }

    enum Convert {
        /// Conversion
        static var kicker: String {
            tr("convert.kicker")
        }

        /// HEIC, JPEG, PNG, H.264, HEVC — for the whole batch at once, keeping the capture date and the
        /// location tag.
        static var text: String {
            tr("convert.text")
        }

        /// Any format for any job
        static var title: String {
            tr("convert.title")
        }
    }

    enum Scan {
        /// Scan
        static var kicker: String {
            tr("scan.kicker")
        }

        /// Shoot the pages one after another: the bounds are found on their own, the frame is
        /// straightened, everything lands in a single PDF.
        static var text: String {
            tr("scan.text")
        }

        /// A document into a PDF in one shoot
        static var title: String {
            tr("scan.title")
        }
    }

    enum Tour {
        /// Close
        static var close: String {
            tr("tour.close")
        }

        /// Next
        static var next: String {
            tr("tour.next")
        }

        /// Skip
        static var skip: String {
            tr("tour.skip")
        }

        /// Start
        static var start: String {
            tr("tour.start")
        }

        /// Step %lld of %lld
        static func step(_ p1: Int, _ p2: Int) -> String {
            tr("tour.step", p1, p2)
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
