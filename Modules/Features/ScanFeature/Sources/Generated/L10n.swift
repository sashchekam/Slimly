// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Camera {
        /// Point the camera at a page
        static var aimHint: String {
            tr("camera.aimHint")
        }

        /// Auto capture
        static var autoCapture: String {
            tr("camera.autoCapture")
        }

        /// Bounds found · hold steady
        static var boundsFound: String {
            tr("camera.boundsFound")
        }

        /// Cancel
        static var cancel: String {
            tr("camera.cancel")
        }

        /// Allow the camera in Settings — pages can be shot or picked from your library
        static var deniedNote: String {
            tr("camera.deniedNote")
        }

        /// No access to the camera
        static var deniedTitle: String {
            tr("camera.deniedTitle")
        }

        /// Done
        static var done: String {
            tr("camera.done")
        }

        /// Done · %lld
        static func doneCount(_ p1: Int) -> String {
            tr("camera.doneCount", p1)
        }

        /// Shoot the first page
        static var firstPage: String {
            tr("camera.firstPage")
        }

        /// Flash: %@
        static func flash(_ p1: String) -> String {
            tr("camera.flash", p1)
        }

        /// Auto
        static var flashAuto: String {
            tr("camera.flashAuto")
        }

        /// On
        static var flashOn: String {
            tr("camera.flashOn")
        }

        /// Focusing · hold steady
        static var focusing: String {
            tr("camera.focusing")
        }

        /// Limit reached — %@
        static func limitReached(_ p1: String) -> String {
            tr("camera.limitReached", p1)
        }

        /// At most %@ at a time
        static func limitSpoken(_ p1: String) -> String {
            tr("camera.limitSpoken", p1)
        }

        /// Manual
        static var manual: String {
            tr("camera.manual")
        }

        /// Manual mode · press the shutter
        static var manualHint: String {
            tr("camera.manualHint")
        }

        /// Open Settings
        static var openSettings: String {
            tr("camera.openSettings")
        }

        /// Page %lld captured
        static func pageCaptured(_ p1: Int) -> String {
            tr("camera.pageCaptured", p1)
        }

        /// Shoot a page
        static var shutter: String {
            tr("camera.shutter")
        }
    }

    enum Corner {
        /// Bottom left corner
        static var bottomLeft: String {
            tr("corner.bottomLeft")
        }

        /// Bottom right corner
        static var bottomRight: String {
            tr("corner.bottomRight")
        }

        /// Top left corner
        static var topLeft: String {
            tr("corner.topLeft")
        }

        /// Top right corner
        static var topRight: String {
            tr("corner.topRight")
        }
    }

    enum Format {
        /// Assemble the scan
        static var action: String {
            tr("format.action")
        }

        /// The frame is straightened along the chosen bounds and the background is pushed to white. B/w
        /// gives the crispest text, color is for stamps and pictures. The document can be saved to
        /// Files — the originals stay in your library.
        static var note: String {
            tr("format.note")
        }

        /// Photo
        static var source: String {
            tr("format.source")
        }

        /// How to assemble the scan
        static var title: String {
            tr("format.title")
        }
    }

    enum Intro {
        /// Use the camera
        static var camera: String {
            tr("intro.camera")
        }

        /// Bounds are caught on the fly, adjust them afterwards
        static var cameraHint: String {
            tr("intro.cameraHint")
        }

        /// Pick photos
        static var library: String {
            tr("intro.library")
        }

        /// Up to %lld pages from your library
        static func libraryHint(_ p1: Int) -> String {
            tr("intro.libraryHint", p1)
        }

        /// We find the sheet bounds, straighten the page and assemble a PDF — the frame can be adjusted
        /// by hand
        static var note: String {
            tr("intro.note")
        }

        /// Document scan
        static var title: String {
            tr("intro.title")
        }
    }

    enum Pages {
        /// Next · %@
        static func action(_ p1: String) -> String {
            tr("pages.action", p1)
        }

        /// Drag the corners if the frame missed the edge
        static var adjustHint: String {
            tr("pages.adjustHint")
        }

        /// No crop
        static var noCrop: String {
            tr("pages.noCrop")
        }

        /// No bounds found — drag the corners to the edge of the page
        static var notFound: String {
            tr("pages.notFound")
        }

        /// Page %lld
        static func page(_ p1: Int) -> String {
            tr("pages.page", p1)
        }

        /// Reset
        static var reset: String {
            tr("pages.reset")
        }

        /// Looking for the sheet bounds…
        static var searching: String {
            tr("pages.searching")
        }

        /// Page %lld of %lld · %@
        static func subtitle(_ p1: Int, _ p2: Int, _ p3: String) -> String {
            tr("pages.subtitle", p1, p2, p3)
        }

        /// Page bounds
        static var title: String {
            tr("pages.title")
        }
    }

    enum Picker {
        /// Pages follow the order you pick them
        static var hint: String {
            tr("picker.hint")
        }

        /// Scan pages
        static var title: String {
            tr("picker.title")
        }
    }

    enum Status {
        /// frame adjusted
        static var adjusted: String {
            tr("status.adjusted")
        }

        /// sheet found
        static var found: String {
            tr("status.found")
        }

        /// sheet not found
        static var notFound: String {
            tr("status.notFound")
        }

        /// looking for the sheet
        static var searching: String {
            tr("status.searching")
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
