// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum AudioFormat {
        /// M4A · %lld kbps
        static func aac(_ p1: Int) -> String {
            tr("audioFormat.aac", p1)
        }

        /// WAV · lossless
        static var wav: String {
            tr("audioFormat.wav")
        }
    }

    enum Badge {
        /// PHOTO
        static var photo: String {
            tr("badge.photo")
        }

        /// VIDEO
        static var video: String {
            tr("badge.video")
        }
    }

    enum Count {
        /// %lld conversions
        static func conversion(_ p1: Int) -> String {
            tr("count.conversion", p1)
        }

        /// %lld files
        static func file(_ p1: Int) -> String {
            tr("count.file", p1)
        }

        /// %lld pages
        static func page(_ p1: Int) -> String {
            tr("count.page", p1)
        }

        /// %lld photos
        static func photo(_ p1: Int) -> String {
            tr("count.photo", p1)
        }

        /// %lld scans
        static func scan(_ p1: Int) -> String {
            tr("count.scan", p1)
        }

        /// %lld tracks
        static func track(_ p1: Int) -> String {
            tr("count.track", p1)
        }

        /// %lld videos
        static func video(_ p1: Int) -> String {
            tr("count.video", p1)
        }
    }

    enum Date {
        /// Today
        static var today: String {
            tr("date.today")
        }

        /// Yesterday
        static var yesterday: String {
            tr("date.yesterday")
        }
    }

    enum Digest {
        /// Nothing processed yet
        static var empty: String {
            tr("digest.empty")
        }

        /// since %@ · %@
        static func since(_ p1: String, _ p2: String) -> String {
            tr("digest.since", p1, p2)
        }
    }

    enum Failure {
        /// Backgrounded
        static var interrupted: String {
            tr("failure.interrupted")
        }

        /// Out of space
        static var noSpace: String {
            tr("failure.noSpace")
        }

        /// None
        static var none: String {
            tr("failure.none")
        }

        /// Saving forbidden
        static var saveDenied: String {
            tr("failure.saveDenied")
        }

        /// Broken file
        static var unreadable: String {
            tr("failure.unreadable")
        }
    }

    enum FailureDetail {
        /// Processing was interrupted by the system
        static var interrupted: String {
            tr("failureDetail.interrupted")
        }

        /// Not enough space on the device for a copy
        static var noSpace: String {
            tr("failureDetail.noSpace")
        }

        /// iOS refused to save the result to the photo library
        static var saveDenied: String {
            tr("failureDetail.saveDenied")
        }

        /// The file is damaged or still downloading from iCloud
        static var unreadable: String {
            tr("failureDetail.unreadable")
        }
    }

    enum Kind {
        /// Audio extraction
        static var audioExtraction: String {
            tr("kind.audioExtraction")
        }

        /// Compression
        static var compression: String {
            tr("kind.compression")
        }

        /// Conversion
        static var conversion: String {
            tr("kind.conversion")
        }

        /// Document scan
        static var scan: String {
            tr("kind.scan")
        }
    }

    enum KindShort {
        /// Audio
        static var audioExtraction: String {
            tr("kindShort.audioExtraction")
        }

        /// Compression
        static var compression: String {
            tr("kindShort.compression")
        }

        /// Conversion
        static var conversion: String {
            tr("kindShort.conversion")
        }

        /// Scans
        static var scan: String {
            tr("kindShort.scan")
        }
    }

    enum LibraryError {
        /// No access to the photo library
        static var accessDenied: String {
            tr("libraryError.accessDenied")
        }

        /// File not found in the photo library
        static var itemNotFound: String {
            tr("libraryError.itemNotFound")
        }

        /// The original is still in iCloud
        static var originalUnavailable: String {
            tr("libraryError.originalUnavailable")
        }
    }

    enum Palette {
        /// b/w
        static var blackAndWhite: String {
            tr("palette.blackAndWhite")
        }

        /// color
        static var color: String {
            tr("palette.color")
        }

        /// gray
        static var gray: String {
            tr("palette.gray")
        }
    }

    enum Period {
        /// All time
        static var allTime: String {
            tr("period.allTime")
        }

        /// all time
        static var allTimeInline: String {
            tr("period.allTimeInline")
        }

        /// 30 days
        static var month: String {
            tr("period.month")
        }

        /// 90 days
        static var quarter: String {
            tr("period.quarter")
        }
    }

    enum Quality {
        /// Light
        static var light: String {
            tr("quality.light")
        }

        /// Maximum
        static var maximum: String {
            tr("quality.maximum")
        }

        /// Medium
        static var medium: String {
            tr("quality.medium")
        }
    }

    enum QualitySummary {
        /// 1080p, all but indistinguishable from the original
        static var light: String {
            tr("qualitySummary.light")
        }

        /// 720p, visible on fine detail
        static var maximum: String {
            tr("qualitySummary.maximum")
        }

        /// 1080p, lower bitrate — for messengers and cloud
        static var medium: String {
            tr("qualitySummary.medium")
        }
    }

    enum Size {
        /// GB
        static var gigabyte: String {
            tr("size.gigabyte")
        }

        /// MB
        static var megabyte: String {
            tr("size.megabyte")
        }
    }

    enum Unit {
        /// conversions
        static func conversion(_ p1: Int) -> String {
            tr("unit.conversion", p1)
        }

        /// files
        static func file(_ p1: Int) -> String {
            tr("unit.file", p1)
        }

        /// pages
        static func page(_ p1: Int) -> String {
            tr("unit.page", p1)
        }

        /// photos
        static func photo(_ p1: Int) -> String {
            tr("unit.photo", p1)
        }

        /// scans
        static func scan(_ p1: Int) -> String {
            tr("unit.scan", p1)
        }

        /// tracks
        static func track(_ p1: Int) -> String {
            tr("unit.track", p1)
        }

        /// videos
        static func video(_ p1: Int) -> String {
            tr("unit.video", p1)
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
