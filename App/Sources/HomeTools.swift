import AudioFeatureInterface
import CompressFeatureInterface
import ConvertFeatureInterface
import HomeFeature
import ScanFeatureInterface
import SlimlyNavigation
import SlimlyShortcuts

/// Состав хаба инструментов. Живёт в App: только здесь видны маршруты всех
/// фич сразу — главный экран про соседние модули ничего не знает и получает
/// готовый список.
///
/// Имена, подписи и иконки берутся из общего каталога — тот же список
/// показывают виджеты и меню иконки, и расходиться им нельзя. Здесь к каждому
/// инструменту добавляется маршрут: за пределами приложения его нет, поэтому
/// в каталоге он и не живёт.
enum HomeTools {
    static let all: [HomeTool] = ToolShortcut.all.map(card)

    private static func card(for shortcut: ToolShortcut) -> HomeTool {
        switch shortcut.id {
        case .compress:
            tool(shortcut, route: CompressRoute.picker)
        case .convertPhoto:
            tool(shortcut, route: ConvertRoute.picker(.photo))
        case .convertVideo:
            tool(shortcut, route: ConvertRoute.picker(.video))
        case .scan:
            // Первый шаг скана — выбор источника, а не экран работы: шторка
            // над хабом, из которой уже открывается камера или галерея.
            tool(shortcut, route: ScanRoute.intro, presentation: .sheet)
        case .audio:
            tool(shortcut, route: AudioRoute.picker)
        }
    }

    private static func tool(
        _ shortcut: ToolShortcut,
        route: any Route,
        presentation: RoutePresentation = .push
    ) -> HomeTool {
        HomeTool(
            id: shortcut.id.rawValue,
            title: shortcut.title,
            subtitle: shortcut.subtitle,
            icon: shortcut.icon,
            route: route,
            presentation: presentation
        )
    }
}
