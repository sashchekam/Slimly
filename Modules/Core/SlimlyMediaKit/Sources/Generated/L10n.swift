// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Failure {
        /// Audio can only be extracted from video
        static var audioFromPhoto: String {
            tr("failure.audioFromPhoto")
        }

        /// The camera is unavailable on this device
        static var cameraUnavailable: String {
            tr("failure.cameraUnavailable")
        }

        /// The shot did not work out: %@
        static func captureFailed(_ p1: String) -> String {
            tr("failure.captureFailed", p1)
        }

        /// Format %@ is not available for conversion
        static func conversionFormat(_ p1: String) -> String {
            tr("failure.conversionFormat", p1)
        }

        /// The video has no audio
        static var noAudioTrack: String {
            tr("failure.noAudioTrack")
        }

        /// The file has no video track
        static var noVideoTrack: String {
            tr("failure.noVideoTrack")
        }

        /// A page is assembled together with the document
        static var pageAlone: String {
            tr("failure.pageAlone")
        }

        /// Could not assemble a PDF from the pages
        static var pdfAssembly: String {
            tr("failure.pdfAssembly")
        }

        /// A photo cannot be saved as %@
        static func photoTarget(_ p1: String) -> String {
            tr("failure.photoTarget", p1)
        }

        /// The finished file was not found
        static var resultMissing: String {
            tr("failure.resultMissing")
        }

        /// Could not save the file to the photo library
        static var saveFailed: String {
            tr("failure.saveFailed")
        }

        /// The file cannot be read
        static var unreadable: String {
            tr("failure.unreadable")
        }

        /// Format %@ is not available on this device
        static func unsupportedFormat(_ p1: String) -> String {
            tr("failure.unsupportedFormat", p1)
        }

        /// Video cannot be saved as %@
        static func videoTarget(_ p1: String) -> String {
            tr("failure.videoTarget", p1)
        }

        /// Could not write the result: %@
        static func writeFailed(_ p1: String) -> String {
            tr("failure.writeFailed", p1)
        }
    }

    enum Library {
        /// Recents
        static var recents: String {
            tr("library.recents")
        }
    }

    enum Playback {
        /// Pause
        static var pause: String {
            tr("playback.pause")
        }

        /// Play
        static var play: String {
            tr("playback.play")
        }
    }

    enum Reason {
        /// the frame was empty
        static var emptyFrame: String {
            tr("reason.emptyFrame")
        }

        /// the file was not finalized
        static var notFinalized: String {
            tr("reason.notFinalized")
        }

        /// the page did not render
        static var pageNotRendered: String {
            tr("reason.pageNotRendered")
        }

        /// writing never started
        static var writerNotStarted: String {
            tr("reason.writerNotStarted")
        }
    }

    enum Scan {
        /// Scan %@.pdf
        static func fileName(_ p1: String) -> String {
            tr("scan.fileName", p1)
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
