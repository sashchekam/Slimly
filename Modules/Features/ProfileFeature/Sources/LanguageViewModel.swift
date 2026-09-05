import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class LanguageViewModel {
    /// Строка списка — один язык.
    public struct Row: Identifiable, Sendable {
        public let id: AppLanguage
        /// Название на самом языке. Не переводится и не подставляется
        /// в строковый каталог: оно уже написано на нужном языке.
        public let nativeName: String
        /// Подпись под ним — то же название на языке интерфейса, а у языка
        /// телефона ещё и пометка про него.
        public let caption: String
        public let code: String
        public let isSelected: Bool
    }

    public private(set) var preferred: AppLanguage?

    private let localization: any LocalizationService
    private let analytics: ProfileAnalytics
    /// Язык, на котором приложение говорит прямо сейчас: на нём подписаны
    /// строки списка. После выбора экран пересобирается вместе со всем
    /// деревом, и сюда приходит уже новая локаль.
    private let locale: Locale
    private let router: Router

    public init(
        localization: any LocalizationService,
        analytics: ProfileAnalytics,
        locale: Locale = L10nBundle.locale,
        router: Router
    ) {
        self.localization = localization
        self.analytics = analytics
        self.locale = locale
        self.router = router
        preferred = localization.preferred
    }

    // MARK: Как в телефоне

    /// Отмечена ли строка «как в телефоне»: ручного выбора нет.
    public var followsDevice: Bool { preferred == nil }

    /// Что сейчас в телефоне — и есть ли у нас такой язык.
    ///
    /// После ручного выбора телефон приложению не виден, и строка становится
    /// описанием действия: назвать язык, которого не знаешь, — соврать.
    /// Языка может и не быть среди наших: тогда честнее сказать, чем
    /// приложение ответит, чем промолчать про подмену.
    public var deviceNote: String {
        guard let identifier = localization.deviceIdentifier else {
            return L10n.Language.backToPhone
        }

        if let device = AppLanguage.closest(to: identifier) {
            let name = device.name(in: locale)
            return L10n.Language.phoneNow(name)
        }

        let name = AppLanguage.nativeName(of: identifier)
        return L10n.Language.untranslated(name)
    }

    // MARK: Список

    public var rows: [Row] {
        let device = localization.deviceLanguage

        return AppLanguage.allCases.map { language in
            let name = language.name(in: locale)

            return Row(
                id: language,
                nativeName: language.nativeName,
                caption: language == device
                    ? L10n.Language.phoneCaption(name)
                    : name,
                code: language.code,
                isSelected: language == preferred
            )
        }
    }

    /// Что случится дальше — и почему список ниже выглядит именно так.
    public var footnote: String {
        guard preferred == nil else {
            return L10n.Language.footnoteManual
        }

        return L10n.Language.footnoteSystem
    }

    // MARK: Выбор

    /// - Parameter language: `nil` — вернуться к языку телефона.
    public func select(_ language: AppLanguage?) {
        guard language != preferred else { return }

        preferred = language
        localization.setPreferred(language)
        analytics.didChangeLanguage(to: language)
    }

    public func goBack() {
        router.pop()
    }
}
