import Foundation
import Observation
import HomeFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class WelcomeViewModel {
    public var email: String = ""
    public var password: String = ""
    public private(set) var isLoading = false
    public private(set) var errorText: String?

    public var isSubmitEnabled: Bool {
        !isLoading && email.contains("@") && password.count >= 4
    }

    private let authService: any AuthService
    /// Навигация передаётся явно в конструктор — так ViewModel тестируется
    /// как чистая функция над состоянием роутера.
    private let router: Router

    public init(authService: any AuthService, router: Router) {
        self.authService = authService
        self.router = router
    }

    public func submit() async {
        guard isSubmitEnabled else { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signIn(email: email, password: password)
            // Фича знает только чужой маршрут из `HomeFeatureInterface`,
            // но не реализацию: экран подставит резолвер, собранный в App.
            router.restart(with: HomeRoute.dashboard)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
