import ProfileFeatureInterface
import SlimlyCore
import SlimlyNavigation

public enum ProfileFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService
    ) -> RouteResolver {
        RouteResolver(for: ProfileRoute.self) { route, router in
            switch route {
            case .profile:
                ProfileView(
                    viewModel: ProfileViewModel(
                        mediaLibrary: mediaLibrary,
                        processingService: processingService,
                        router: router
                    )
                )
            }
        }
    }
}
