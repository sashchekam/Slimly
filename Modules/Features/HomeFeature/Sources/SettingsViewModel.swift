import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation
import WelcomeFeatureInterface

@MainActor
@Observable
public final class SettingsViewModel {
    private let authService: any AuthService
    private let router: Router

    public init(authService: any AuthService, router: Router) {
        self.authService = authService
        self.router = router
    }

    public func close() {
        router.dismiss()
    }

    public func signOut() async {
        await authService.signOut()
        // Роутер модалки сам сворачивает всю иерархию до корня и ставит новый мир.
        router.restart(with: WelcomeRoute.signIn)
    }
}
