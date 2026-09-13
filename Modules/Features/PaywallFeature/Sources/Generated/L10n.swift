// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Benefit {
        /// More files in one go
        static var batch: String {
            tr("benefit.batch")
        }

        /// Everything new as soon as it ships
        static var next: String {
            tr("benefit.next")
        }

        /// Scanning without a page limit
        static var pages: String {
            tr("benefit.pages")
        }

        /// Maximum quality and full resolution
        static var quality: String {
            tr("benefit.quality")
        }
    }

    enum Count {
        /// %lld days
        static func day(_ p1: Int) -> String {
            tr("count.day", p1)
        }
    }

    enum Paywall {
        /// Limits are off in every tool. Thanks for supporting the app.
        static var activeNote: String {
            tr("paywall.activeNote")
        }

        /// Slimly Pro is on
        static var activeTitle: String {
            tr("paywall.activeTitle")
        }

        /// Close
        static var close: String {
            tr("paywall.close")
        }

        /// Done
        static var done: String {
            tr("paywall.done")
        }

        /// That didn’t go through. Try again.
        static var failed: String {
            tr("paywall.failed")
        }

        /// The subscription renews automatically until you cancel it in your Apple ID settings.
        static var legal: String {
            tr("paywall.legal")
        }

        /// No purchases to restore.
        static var nothingToRestore: String {
            tr("paywall.nothingToRestore")
        }

        /// %@ per month
        static func perMonth(_ p1: String) -> String {
            tr("paywall.perMonth", p1)
        }

        /// Charged right away, cancel any time
        static var renewNote: String {
            tr("paywall.renewNote")
        }

        /// Restore purchases
        static var restore: String {
            tr("paywall.restore")
        }

        /// Subscription restored.
        static var restored: String {
            tr("paywall.restored")
        }

        /// Try again
        static var retry: String {
            tr("paywall.retry")
        }

        /// Save %@
        static func save(_ p1: String) -> String {
            tr("paywall.save", p1)
        }

        /// Subscribe
        static var subscribe: String {
            tr("paywall.subscribe")
        }

        /// More files at a time and the highest quality — in every tool.
        static var subtitle: String {
            tr("paywall.subtitle")
        }

        /// Everything without limits
        static var title: String {
            tr("paywall.title")
        }

        /// %@ free, then the plan you picked
        static func trialNote(_ p1: String) -> String {
            tr("paywall.trialNote", p1)
        }

        /// Try it free
        static var tryFree: String {
            tr("paywall.tryFree")
        }

        /// Plans aren’t available right now. Check your connection and try again.
        static var unavailable: String {
            tr("paywall.unavailable")
        }
    }

    enum Plan {
        /// Forever
        static var lifetime: String {
            tr("plan.lifetime")
        }

        /// Month
        static var month: String {
            tr("plan.month")
        }

        /// Plan
        static var other: String {
            tr("plan.other")
        }

        /// Week
        static var week: String {
            tr("plan.week")
        }

        /// Year
        static var year: String {
            tr("plan.year")
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
