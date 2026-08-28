import Foundation
import Observation
import HomeFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var profile: UserProfile?

    private let authService: any AuthService
    private let router: Router

    public init(authService: any AuthService, router: Router) {
        self.authService = authService
        self.router = router
    }

    public func load() async {
        if case let .signedIn(profile) = await authService.state {
            self.profile = profile
        }
    }

    public func openProfile() {
        router.push(HomeRoute.profile)
    }

    public func openSettings() {
        router.present(HomeRoute.settings)
    }
}
