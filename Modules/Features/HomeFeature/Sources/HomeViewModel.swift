import Foundation
import Observation
import SlimlyNavigation

@MainActor
@Observable
public final class HomeViewModel {
    public let tools: [HomeTool]

    private let profile: any Route
    private let router: Router

    public init(tools: [HomeTool], profile: any Route, router: Router) {
        self.tools = tools
        self.profile = profile
        self.router = router
    }

    /// Макет показывает дневной вариант, но одна и та же строка круглые
    /// сутки читалась бы как баг — время берём в момент показа.
    public var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "Доброе утро"
        case 12..<18: "Добрый день"
        case 18..<23: "Добрый вечер"
        default: "Доброй ночи"
        }
    }

    public func open(_ tool: HomeTool) {
        router.show(tool.route, as: tool.presentation)
    }

    public func openProfile() {
        router.push(profile)
    }
}
