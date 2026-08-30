import Foundation
import AudioFeatureInterface
import CompressFeatureInterface
import ConvertFeatureInterface
import DebugFeatureInterface
import HomeFeatureInterface
import ProfileFeatureInterface
import ScanFeatureInterface
import SlimlyCore
import SlimlyNavigation

/// Таблица «URL → маршруты». Живёт в App: только здесь видны маршруты всех фич.
///
/// Первым идёт главный экран: ссылка открывает инструмент, но возврат должен
/// вести на хаб, а не в пустоту. Внутренние шаги флоу ссылками не открываются —
/// они требуют конкретных файлов медиатеки, а такое в URL не положишь.
enum DeeplinkMap {
    static let mappers: [DeeplinkRegistry.Mapper] = {
        var mappers: [DeeplinkRegistry.Mapper] = [
            home,
            compress,
            convert,
            audio,
            scan,
            profile,
        ]
        #if DEBUG
        mappers.append(debug)
        #endif
        return mappers
    }()

    /// `slimly://home`
    private static let home: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "home", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home]
    }

    /// `slimly://compress`
    private static let compress: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "compress", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home, CompressRoute.picker]
    }

    /// `slimly://convert/photo`, `slimly://convert/video`
    private static let convert: DeeplinkRegistry.Mapper = { deeplink in
        guard
            deeplink.host == "convert",
            deeplink.pathComponents.count == 1,
            let kind = ConvertKind(rawValue: deeplink.pathComponents[0])
        else { return nil }
        return [HomeRoute.home, ConvertRoute.picker(kind)]
    }

    /// `slimly://audio`
    private static let audio: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "audio", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home, AudioRoute.picker]
    }

    /// `slimly://scan`
    private static let scan: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "scan", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home, ScanRoute.intro]
    }

    /// `slimly://profile`
    private static let profile: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "profile", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home, ProfileRoute.profile]
    }

    #if DEBUG
    /// `slimly://debug` — отладочное меню пушем. Тряска в симуляторе есть
    /// (⌃⌘Z), но одной командой из терминала до меню быстрее.
    private static let debug: DeeplinkRegistry.Mapper = { deeplink in
        guard deeplink.host == "debug", deeplink.pathComponents.isEmpty else { return nil }
        return [HomeRoute.home, DebugRoute.menu]
    }
    #endif
}
