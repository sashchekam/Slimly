import SlimlyCore
import SlimlyNavigation
import WelcomeFeatureInterface

/// Точка сборки фичи. Зависимости приходят снаружи явными параметрами:
/// фича не знает про DI-контейнер приложения.
public enum WelcomeFeature {
    @MainActor
    public static func resolver(authService: any AuthService) -> RouteResolver {
        RouteResolver(for: WelcomeRoute.self) { route, router in
            switch route {
            case .signIn:
                WelcomeView(viewModel: WelcomeViewModel(authService: authService, router: router))
            }
        }
    }
}
