import Foundation

public enum AuthState: Sendable, Equatable {
    case signedOut
    case signedIn(UserProfile)
}

public protocol AuthService: Sendable {
    var state: AuthState { get async }
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() async
}

/// Заглушка для запуска приложения без бэкенда.
public actor StubAuthService: AuthService {
    private var current: AuthState = .signedOut

    public init() {}

    public var state: AuthState { current }

    public func signIn(email: String, password: String) async throws -> UserProfile {
        let profile = UserProfile(
            name: email.split(separator: "@").first.map(String.init) ?? "Гость",
            currentWeight: .init(value: 82, unit: .kilograms),
            goalWeight: .init(value: 74, unit: .kilograms)
        )
        current = .signedIn(profile)
        return profile
    }

    public func signOut() async {
        current = .signedOut
    }
}
