import CompressFeatureInterface
import ProfileFeatureInterface
import SlimlyDesignSystem
import SlimlyNavigation

/// Табы приложения. Живут в App: только здесь известны маршруты всех фич
/// сразу — фича про соседний таб ничего не знает.
enum SqueezeTab: String, CaseIterable, Identifiable {
    case compress
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compress: "Сжать"
        case .profile: "Профиль"
        }
    }

    var icon: SlimlyIcon.Kind {
        switch self {
        case .compress: .compress
        case .profile: .person
        }
    }

    /// Корень таба уже стёртый: у табов разные типы маршрутов, и общего
    /// статического типа для них нет.
    var root: AnyRoute {
        switch self {
        case .compress: AnyRoute(CompressRoute.gallery)
        case .profile: AnyRoute(ProfileRoute.profile)
        }
    }

    /// Какому табу принадлежит маршрут. Нужно диплинкам: URL называет экран,
    /// а таб выводится из того, чья это фича.
    static func owner(of route: any Route) -> SqueezeTab? {
        switch route {
        case is CompressRoute: .compress
        case is ProfileRoute: .profile
        default: nil
        }
    }

    static var routerItems: [TabRouter.Item] {
        allCases.map { TabRouter.Item(id: $0.id, root: $0.root) }
    }
}
