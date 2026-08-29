import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum ProfileFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        compressionService: any CompressionService
    ) -> RouteResolver {
        RouteResolver(for: ProfileRoute.self) { route, _ in
            switch route {
            case .profile:
                ProfileView(
                    viewModel: ProfileViewModel(
                        mediaLibrary: mediaLibrary,
                        compressionService: compressionService
                    )
                )
            }
        }
    }
}
