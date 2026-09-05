import Foundation
import Observation
import SlimlyNavigation

@MainActor
@Observable
public final class HomeViewModel {
    /// Список собирается на каждом обращении, а не хранится готовым: подписи
    /// плиток переведены, а язык меняют на ходу — снимок остался бы
    /// на прежнем.
    public var tools: [HomeTool] { makeTools() }

    private let makeTools: @MainActor () -> [HomeTool]
    private let profile: any Route
    private let analytics: HomeAnalytics
    private let router: Router

    public init(
        tools: @escaping @MainActor () -> [HomeTool],
        profile: any Route,
        analytics: HomeAnalytics,
        router: Router
    ) {
        makeTools = tools
        self.profile = profile
        self.analytics = analytics
        self.router = router
    }

    /// Макет показывает дневной вариант, но одна и та же строка круглые
    /// сутки читалась бы как баг — время берём в момент показа.
    public var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: L10n.Greeting.morning
        case 12..<18: L10n.Greeting.afternoon
        case 18..<23: L10n.Greeting.evening
        default: L10n.Greeting.night
        }
    }

    public func open(_ tool: HomeTool) {
        analytics.didOpenTool(tool)
        router.show(tool.route, as: tool.presentation)
    }

    public func openProfile() {
        analytics.didOpenProfile()
        router.push(profile)
    }
}
