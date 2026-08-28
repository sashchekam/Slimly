import Foundation
import Observation
import SlimlyCore

@MainActor
@Observable
public final class ProfileViewModel {
    public private(set) var profile: UserProfile?

    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func load() async {
        if case let .signedIn(profile) = await authService.state {
            self.profile = profile
        }
    }
}
