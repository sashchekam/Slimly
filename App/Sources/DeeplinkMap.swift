import Foundation
import CompressFeatureInterface
import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

/// Таблица «URL → маршруты». Живёт в App: только здесь видны маршруты всех фич.
///
/// Первый элемент результата становится корнем стека, остальные — экранами
/// поверх. Внутренние шаги сжатия ссылками не открываются: они требуют
/// конкретных файлов медиатеки, а такое в URL не положишь.
enum DeeplinkMap {
    static let mappers: [DeeplinkRegistry.Mapper] = [
        compress,
        profile,
    ]

    /// `slimly://compress`
    private static let compress: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "compress", deeplink.pathComponents.isEmpty else { return nil }
        return [CompressRoute.gallery]
    }

    /// `slimly://profile`
    private static let profile: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "profile", deeplink.pathComponents.isEmpty else { return nil }
        return [ProfileRoute.profile]
    }
}
