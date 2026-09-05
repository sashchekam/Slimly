// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Badge {
        /// COMPRESSED COPY
        static var compressed: String {
            tr("badge.compressed")
        }

        /// DOCUMENT
        static var document: String {
            tr("badge.document")
        }

        /// ORIGINAL
        static var original: String {
            tr("badge.original")
        }

        /// RESULT
        static var result: String {
            tr("badge.result")
        }

        /// TRACK
        static var track: String {
            tr("badge.track")
        }

        /// VIDEO
        static var video: String {
            tr("badge.video")
        }
    }

    enum Common {
        /// Done
        static var done: String {
            tr("common.done")
        }
    }

    enum Format {
        /// from
        static var from: String {
            tr("format.from")
        }

        /// Result format
        static var title: String {
            tr("format.title")
        }

        /// to
        static var to: String {
            tr("format.to")
        }

        /// track ≈ %@
        static func trackEstimate(_ p1: String) -> String {
            tr("format.trackEstimate", p1)
        }
    }

    enum Grid {
        /// %lld per row
        static func density(_ p1: Int) -> String {
            tr("grid.density", p1)
        }
    }

    enum Hint {
        /// Tap a track to listen
        static var audio: String {
            tr("hint.audio")
        }

        /// Tap a file to compare before and after
        static var compression: String {
            tr("hint.compression")
        }

        /// Tap a file to open the preview
        static var preview: String {
            tr("hint.preview")
        }
    }

    enum Outcome {
        /// Not a single file could be processed — details below.
        static var allFailed: String {
            tr("outcome.allFailed")
        }

        /// Delete originals
        static var deleteOriginals: String {
            tr("outcome.deleteOriginals")
        }

        /// %@, %@ · iOS will show its own prompt
        static func deletePrompt(_ p1: String, _ p2: String) -> String {
            tr("outcome.deletePrompt", p1, p2)
        }

        /// Failed: %@
        static func failed(_ p1: String) -> String {
            tr("outcome.failed", p1)
        }

        /// nothing came of it
        static var nothing: String {
            tr("outcome.nothing")
        }

        /// The originals are still there
        static var originalsKept: String {
            tr("outcome.originalsKept")
        }

        /// Share all · %lld
        static func shareAll(_ p1: Int) -> String {
            tr("outcome.shareAll", p1)
        }

        /// Share file %@
        static func shareFile(_ p1: String) -> String {
            tr("outcome.shareFile", p1)
        }

        /// track %@
        static func trackSize(_ p1: String) -> String {
            tr("outcome.trackSize", p1)
        }
    }

    enum Picker {
        /// Next · %@
        static func action(_ p1: String) -> String {
            tr("picker.action", p1)
        }

        /// Next · %@ · %@
        static func actionWithSize(_ p1: String, _ p2: String) -> String {
            tr("picker.actionWithSize", p1, p2)
        }

        /// Album
        static var album: String {
            tr("picker.album")
        }

        /// %lld of %lld
        static func counter(_ p1: Int, _ p2: Int) -> String {
            tr("picker.counter", p1, p2)
        }

        /// Without access to the library there is nothing to pick. Turn the permission on in Settings.
        static var deniedNote: String {
            tr("picker.deniedNote")
        }

        /// No access to Photos
        static var deniedTitle: String {
            tr("picker.deniedTitle")
        }

        /// Deselect
        static var deselect: String {
            tr("picker.deselect")
        }

        /// Nothing to process in the selected album.
        static var emptyAlbum: String {
            tr("picker.emptyAlbum")
        }

        /// The photo library is empty
        static var emptyLibrary: String {
            tr("picker.emptyLibrary")
        }

        /// The app can see only part of your library. Add files from the system list.
        static var emptyLimited: String {
            tr("picker.emptyLimited")
        }

        /// No photos found
        static var emptyPhotos: String {
            tr("picker.emptyPhotos")
        }

        /// No videos found
        static var emptyVideos: String {
            tr("picker.emptyVideos")
        }

        /// Grid
        static var grid: String {
            tr("picker.grid")
        }

        /// Only part of the library is open — these are just the files you granted access to.
        static var limitedNote: String {
            tr("picker.limitedNote")
        }

        /// Loading the photo library
        static var loading: String {
            tr("picker.loading")
        }

        /// Open Settings
        static var openSettings: String {
            tr("picker.openSettings")
        }

        /// Recents
        static var recents: String {
            tr("picker.recents")
        }

        /// Select
        static var select: String {
            tr("picker.select")
        }
    }

    enum Preview {
        /// after · %@
        static func afterCaption(_ p1: String) -> String {
            tr("preview.afterCaption", p1)
        }

        /// Compressed · %@
        static func afterTitle(_ p1: String) -> String {
            tr("preview.afterTitle", p1)
        }

        /// A ready track — it sits in Files, in the Slimly folder. The video was not changed.
        static var audio: String {
            tr("preview.audio")
        }

        /// original · %@
        static func beforeCaption(_ p1: String) -> String {
            tr("preview.beforeCaption", p1)
        }

        /// Original · %@
        static func beforeTitle(_ p1: String) -> String {
            tr("preview.beforeTitle", p1)
        }

        /// A copy in your library, %@ of the weight is gone. The original is untouched.
        static func compression(_ p1: String) -> String {
            tr("preview.compression", p1)
        }

        /// A ready %@ in your library. The original stayed as it was.
        static func conversion(_ p1: String) -> String {
            tr("preview.conversion", p1)
        }

        /// Photo
        static var photo: String {
            tr("preview.photo")
        }

        /// A ready %@ — it also sits in Files, in the Slimly folder.
        static func scan(_ p1: String) -> String {
            tr("preview.scan", p1)
        }

        /// The original from your library — for comparison.
        static var sourceCompare: String {
            tr("preview.sourceCompare")
        }

        /// The original from your library — this is how it looks now. Processing does not change it:
        /// the result becomes a separate file.
        static var sourceNote: String {
            tr("preview.sourceNote")
        }

        /// Video track
        static var track: String {
            tr("preview.track")
        }

        /// Video track · %@
        static func trackTime(_ p1: String) -> String {
            tr("preview.trackTime", p1)
        }

        /// Video
        static var video: String {
            tr("preview.video")
        }
    }

    enum Progress {
        /// Cancel
        static var cancel: String {
            tr("progress.cancel")
        }

        /// done
        static var done: String {
            tr("progress.done")
        }

        /// Estimating time · %@
        static func estimating(_ p1: String) -> String {
            tr("progress.estimating", p1)
        }

        /// Runs while the app is open — like exporting from Photos
        static var note: String {
            tr("progress.note")
        }

        /// %@ left · %@
        static func remaining(_ p1: String, _ p2: String) -> String {
            tr("progress.remaining", p1, p2)
        }

        /// waiting
        static var waiting: String {
            tr("progress.waiting")
        }
    }

    enum Save {
        /// Could not save
        static var failed: String {
            tr("save.failed")
        }

        /// Save to Files
        static var files: String {
            tr("save.files")
        }

        /// Saved to Files
        static var filesDone: String {
            tr("save.filesDone")
        }

        /// Saved to the “Slimly” folder in Files
        static var filesFolder: String {
            tr("save.filesFolder")
        }

        /// For now the files live only inside the app — without saving they will be lost
        static var hint: String {
            tr("save.hint")
        }

        /// Not everything was saved
        static var partial: String {
            tr("save.partial")
        }

        /// Save to Photos
        static var photos: String {
            tr("save.photos")
        }

        /// Saved to Photos
        static var photosDone: String {
            tr("save.photosDone")
        }
    }

    enum Stage {
        /// audio extracted
        static var audioDone: String {
            tr("stage.audioDone")
        }

        /// compressing
        static var compressing: String {
            tr("stage.compressing")
        }

        /// compression done
        static var compressionDone: String {
            tr("stage.compressionDone")
        }

        /// format changed
        static var conversionDone: String {
            tr("stage.conversionDone")
        }

        /// converting
        static var converting: String {
            tr("stage.converting")
        }

        /// extracting
        static var extracting: String {
            tr("stage.extracting")
        }

        /// scan assembled
        static var scanDone: String {
            tr("stage.scanDone")
        }

        /// scanning
        static var scanning: String {
            tr("stage.scanning")
        }
    }

    enum Summary {
        /// %@ as %@ · %@ in total · video unchanged
        static func audio(_ p1: String, _ p2: String, _ p3: String) -> String {
            tr("summary.audio", p1, p2, p3)
        }

        /// %@ rebuilt as %@ · originals untouched
        static func conversion(_ p1: String, _ p2: String) -> String {
            tr("summary.conversion", p1, p2)
        }

        /// The files were already dense — the size barely changed · %@
        static func dense(_ p1: String) -> String {
            tr("summary.dense", p1)
        }

        /// Freed up %@
        static func freed(_ p1: String) -> String {
            tr("summary.freed", p1)
        }

        /// originals untouched
        static var originalsUntouched: String {
            tr("summary.originalsUntouched")
        }

        /// %@ in one %@ · originals untouched
        static func scan(_ p1: String, _ p2: String) -> String {
            tr("summary.scan", p1, p2)
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
