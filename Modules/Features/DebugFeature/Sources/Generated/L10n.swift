// Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
// Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

import Foundation
import SlimlyCore

/// Строки модуля.
///
/// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
/// строка читается на месте показа, а не сохраняется в поле.
enum L10n {
    enum Action {
        /// Copy diagnostics
        static var copyDiagnostics: String {
            tr("action.copyDiagnostics")
        }

        /// Diagnostics copied to the clipboard
        static var copyDiagnosticsDone: String {
            tr("action.copyDiagnosticsDone")
        }

        /// version, device, ID
        static var copyDiagnosticsHint: String {
            tr("action.copyDiagnosticsHint")
        }

        /// Copy Documents path
        static var copyDocuments: String {
            tr("action.copyDocuments")
        }

        /// Documents path copied to the clipboard
        static var copyDocumentsDone: String {
            tr("action.copyDocumentsDone")
        }

        /// app sandbox folder
        static var copyDocumentsHint: String {
            tr("action.copyDocumentsHint")
        }

        /// Turn off all overrides
        static var resetKnobs: String {
            tr("action.resetKnobs")
        }

        /// Overrides turned off
        static var resetKnobsDone: String {
            tr("action.resetKnobsDone")
        }

        /// back to how App Store ships it
        static var resetKnobsHint: String {
            tr("action.resetKnobsHint")
        }

        /// Reset statistics
        static var resetStats: String {
            tr("action.resetStats")
        }

        /// Profile statistics reset to zero
        static var resetStatsDone: String {
            tr("action.resetStatsDone")
        }

        /// the profile resets to zero
        static var resetStatsHint: String {
            tr("action.resetStatsHint")
        }
    }

    enum Analytics {
        /// All
        static var all: String {
            tr("analytics.all")
        }

        /// Clear
        static var clear: String {
            tr("analytics.clear")
        }

        /// Log copied
        static var copied: String {
            tr("analytics.copied")
        }

        /// Copy
        static var copy: String {
            tr("analytics.copy")
        }

        /// No events
        static var empty: String {
            tr("analytics.empty")
        }

        /// The app has not sent anything yet. Run any tool and come back here — a record shows up right
        /// away, no need to wait for the web console.
        static var emptyNote: String {
            tr("analytics.emptyNote")
        }

        /// Log cleared
        static var logCleared: String {
            tr("analytics.logCleared")
        }

        /// Events and properties sent to analytics since this launch. The log lives in memory: a
        /// restart wipes it, and until then it keeps the last %lld records.
        static func note(_ p1: Int) -> String {
            tr("analytics.note", p1)
        }

        /// properties
        static var properties: String {
            tr("analytics.properties")
        }

        /// property · %@
        static func property(_ p1: String) -> String {
            tr("analytics.property", p1)
        }

        /// empty
        static var summaryEmpty: String {
            tr("analytics.summaryEmpty")
        }

        /// records: %lld
        static func summaryRecords(_ p1: Int) -> String {
            tr("analytics.summaryRecords", p1)
        }

        /// cleared
        static var valueCleared: String {
            tr("analytics.valueCleared")
        }
    }

    enum Config {
        /// All overrides cleared
        static var allCleared: String {
            tr("config.allCleared")
        }

        /// Clear all overrides
        static var clearAll: String {
            tr("config.clearAll")
        }

        /// Done
        static var doneTyping: String {
            tr("config.doneTyping")
        }

        /// The value is overridden only on this device. An empty field clears the override.
        static var editNote: String {
            tr("config.editNote")
        }

        /// No values
        static var empty: String {
            tr("config.empty")
        }

        /// The config has not loaded yet, the project has no GoogleService-Info.plist, or no parameter
        /// has been published in the web console.
        static var emptyNote: String {
            tr("config.emptyNote")
        }

        /// Format
        static var format: String {
            tr("config.format")
        }

        /// Not valid JSON: check the braces, commas and quotes.
        static var invalid: String {
            tr("config.invalid")
        }

        /// Values from the server and the local overrides on top of them. An override lives only on
        /// this device and survives a restart, while screens read the value when they open.
        static var note: String {
            tr("config.note")
        }

        /// Nothing came from the server
        static var nothingFetched: String {
            tr("config.nothingFetched")
        }

        /// Override
        static var override: String {
            tr("config.override")
        }

        /// Refresh
        static var refresh: String {
            tr("config.refresh")
        }

        /// Restore the server value
        static var restore: String {
            tr("config.restore")
        }

        /// On the server
        static var serverValue: String {
            tr("config.serverValue")
        }

        /// key default
        static var stateDefault: String {
            tr("config.stateDefault")
        }

        /// overridden · from the server %@
        static func stateOverridden(_ p1: String) -> String {
            tr("config.stateOverridden", p1)
        }

        /// overridden · no value on the server
        static var stateOverriddenOnly: String {
            tr("config.stateOverriddenOnly")
        }

        /// overridden
        static var stateOverriddenShort: String {
            tr("config.stateOverriddenShort")
        }

        /// from the server
        static var stateRemote: String {
            tr("config.stateRemote")
        }

        /// values from the server
        static var summary: String {
            tr("config.summary")
        }

        /// overrides: %lld
        static func summaryOverrides(_ p1: Int) -> String {
            tr("config.summaryOverrides", p1)
        }

        /// Values updated
        static var updated: String {
            tr("config.updated")
        }

        /// Value
        static var valueField: String {
            tr("config.valueField")
        }
    }

    enum Knob {
        /// Every file fails with the chosen reason — that is how the list of failures on the outcome
        /// screen becomes visible
        static var failureNote: String {
            tr("knob.failureNote")
        }

        /// Processing failure
        static var failureTitle: String {
            tr("knob.failureTitle")
        }

        /// Shown
        static var seen: String {
            tr("knob.seen")
        }

        /// Free
        static var tierFree: String {
            tr("knob.tierFree")
        }

        /// The tier the tools take their limits from. There are no purchases yet: the flag is set by
        /// hand.
        static var tierNote: String {
            tr("knob.tierNote")
        }

        /// Tier switched — the next picker takes the new limits
        static var tierSwitched: String {
            tr("knob.tierSwitched")
        }

        /// Subscription
        static var tierTitle: String {
            tr("knob.tierTitle")
        }

        /// The tour will show on the next launch
        static var tourCleared: String {
            tr("knob.tourCleared")
        }

        /// The tour is marked as shown
        static var tourMarked: String {
            tr("knob.tourMarked")
        }

        /// The mark that the tour was shown — clear it and restart the app to begin with the tour
        static var tourNote: String {
            tr("knob.tourNote")
        }

        /// Intro tour
        static var tourTitle: String {
            tr("knob.tourTitle")
        }

        /// Not shown
        static var unseen: String {
            tr("knob.unseen")
        }
    }

    enum Menu {
        /// actions
        static var actions: String {
            tr("menu.actions")
        }

        /// Analytics
        static var analytics: String {
            tr("menu.analytics")
        }

        /// Done
        static var close: String {
            tr("menu.close")
        }

        /// The menu opens by shaking the device and lives only in internal builds — it is not in the
        /// App Store.
        static var note: String {
            tr("menu.note")
        }

        /// sections
        static var sections: String {
            tr("menu.sections")
        }

        /// Debug menu
        static var title: String {
            tr("menu.title")
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
