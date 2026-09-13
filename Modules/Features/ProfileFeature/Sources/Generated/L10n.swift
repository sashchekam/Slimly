// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Empty {
        /// No audio was extracted in this period.
        static var audio: String {
            tr("empty.audio")
        }

        /// Nothing was compressed in this period.
        static var compression: String {
            tr("empty.compression")
        }

        /// Nothing was converted in this period.
        static var conversion: String {
            tr("empty.conversion")
        }

        /// Nothing was scanned in this period.
        static var scan: String {
            tr("empty.scan")
        }
    }

    enum Fact {
        /// average gain
        static var averageGain: String {
            tr("fact.averageGain")
        }

        /// captured
        static var captured: String {
            tr("fact.captured")
        }

        /// common pair
        static var commonPair: String {
            tr("fact.commonPair")
        }

        /// duration
        static var duration: String {
            tr("fact.duration")
        }

        /// format
        static var format: String {
            tr("fact.format")
        }

        /// freed up
        static var freed: String {
            tr("fact.freed")
        }

        /// main format
        static var mainFormat: String {
            tr("fact.mainFormat")
        }

        /// mix
        static var mix: String {
            tr("fact.mix")
        }
    }

    enum Language {
        /// Go back to the phone’s language
        static var backToPhone: String {
            tr("language.backToPhone")
        }

        /// Chosen by hand — the phone’s language no longer changes it.
        static var footnoteManual: String {
            tr("language.footnoteManual")
        }

        /// The app follows the phone and picks the closest language it has. If there is none, it speaks
        /// English.
        static var footnoteSystem: String {
            tr("language.footnoteSystem")
        }

        /// choose manually
        static var manual: String {
            tr("language.manual")
        }

        /// Applies at the next launch.
        static var note: String {
            tr("language.note")
        }

        /// %@ · phone language
        static func phoneCaption(_ p1: String) -> String {
            tr("language.phoneCaption", p1)
        }

        /// Now on the phone — %@
        static func phoneNow(_ p1: String) -> String {
            tr("language.phoneNow", p1)
        }

        /// Same as the phone
        static var system: String {
            tr("language.system")
        }

        /// Language
        static var title: String {
            tr("language.title")
        }

        /// %@ isn’t translated — English instead
        static func untranslated(_ p1: String) -> String {
            tr("language.untranslated", p1)
        }
    }

    enum Permission {
        /// All photos
        static var authorized: String {
            tr("permission.authorized")
        }

        /// Denied
        static var denied: String {
            tr("permission.denied")
        }

        /// Selected photos
        static var limited: String {
            tr("permission.limited")
        }

        /// Not requested
        static var notDetermined: String {
            tr("permission.notDetermined")
        }
    }

    enum Pro {
        /// No cap on how many files you process at once
        static var activeNote: String {
            tr("pro.activeNote")
        }

        /// Subscription not connected
        static var inactiveNote: String {
            tr("pro.inactiveNote")
        }

        /// Lifts the cap on how many files you process at once — in every tool.
        static var pitch: String {
            tr("pro.pitch")
        }

        /// active
        static var status: String {
            tr("pro.status")
        }

        /// Subscribe
        static var subscribe: String {
            tr("pro.subscribe")
        }
    }

    enum Profile {
        /// All statistics
        static var allStatistics: String {
            tr("profile.allStatistics")
        }

        /// compressed by us
        static var compressed: String {
            tr("profile.compressed")
        }

        /// %lld more — and the Debug menu opens
        static func debugCountdown(_ p1: Int) -> String {
            tr("profile.debugCountdown", p1)
        }

        /// free
        static var free: String {
            tr("profile.free")
        }

        /// in the library
        static var library: String {
            tr("profile.library")
        }

        /// now %@
        static func now(_ p1: String) -> String {
            tr("profile.now", p1)
        }

        /// over %@
        static func over(_ p1: String) -> String {
            tr("profile.over", p1)
        }

        /// Photos access
        static var photosAccess: String {
            tr("profile.photosAccess")
        }

        /// Profile
        static var title: String {
            tr("profile.title")
        }

        /// what you used
        static var usage: String {
            tr("profile.usage")
        }

        /// Version
        static var version: String {
            tr("profile.version")
        }

        /// was %@
        static func was(_ p1: String) -> String {
            tr("profile.was", p1)
        }
    }

    enum Statistics {
        /// operations by tool
        static var byTool: String {
            tr("statistics.byTool")
        }

        /// A breakdown by tool will show up here — as soon as you compress or convert something.
        static var empty: String {
            tr("statistics.empty")
        }

        /// Nothing was processed in this period. Try a longer one.
        static var emptyPeriod: String {
            tr("statistics.emptyPeriod")
        }

        /// Statistics are computed on device and never sent anywhere.
        static var privacy: String {
            tr("statistics.privacy")
        }

        /// Statistics
        static var title: String {
            tr("statistics.title")
        }

        /// operations in total
        static var total: String {
            tr("statistics.total")
        }
    }

    enum Summary {
        /// Tracks saved as %@, %@ in total.
        static func audio(_ p1: String, _ p2: String) -> String {
            tr("summary.audio", p1, p2)
        }

        /// Freed up %@ — average gain %@.
        static func compression(_ p1: String, _ p2: String) -> String {
            tr("summary.compression", p1, p2)
        }

        /// Most often %@, less often %@.
        static func conversionPair(_ p1: String, _ p2: String) -> String {
            tr("summary.conversionPair", p1, p2)
        }

        /// Always the same pair: %@.
        static func conversionSingle(_ p1: String) -> String {
            tr("summary.conversionSingle", p1)
        }

        /// The system did not name any “from → to” pairs.
        static var conversionUnknown: String {
            tr("summary.conversionUnknown")
        }

        /// %@, on average %@ per document.
        static func scan(_ p1: String, _ p2: String) -> String {
            tr("summary.scan", p1, p2)
        }
    }

    enum Unit {
        /// photos
        static var photos: String {
            tr("unit.photos")
        }

        /// videos
        static var videos: String {
            tr("unit.videos")
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
