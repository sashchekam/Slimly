import Foundation
import HomeFeatureInterface
import SlimlyCore
import SlimlyNavigation
import WelcomeFeatureInterface

/// Таблица «URL → маршруты». Живёт в App: только здесь видны маршруты всех фич.
///
/// Первый элемент результата становится корнем стека, остальные — экранами поверх.
enum DeeplinkMap {
    static let mappers: [DeeplinkRegistry.Mapper] = [
        welcome,
        home,
    ]

    /// `slimly://welcome`
    private static let welcome: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "welcome" else { return nil }
        return [WelcomeRoute.signIn]
    }

    /// `slimly://home`, `slimly://home/profile`
    private static let home: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "home" else { return nil }
        switch deeplink.pathComponents.first {
        case nil: return [HomeRoute.dashboard]
        case "profile": return [HomeRoute.dashboard, HomeRoute.profile]
        default: return nil
        }
    }
}
