import SlimlyCore
import SlimlyNavigation
import HomeFeatureInterface

public enum HomeFeature {
    @MainActor
    public static func resolver(authService: any AuthService) -> RouteResolver {
        RouteResolver(for: HomeRoute.self) { route, router in
            switch route {
            case .dashboard:
                HomeView(viewModel: HomeViewModel(authService: authService, router: router))
            case .profile:
                ProfileView(viewModel: ProfileViewModel(authService: authService))
            case .settings:
                SettingsView(viewModel: SettingsViewModel(authService: authService, router: router))
            }
        }
    }
}
