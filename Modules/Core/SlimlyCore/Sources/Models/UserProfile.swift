import Foundation

public struct UserProfile: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let currentWeight: Measurement<UnitMass>
    public let goalWeight: Measurement<UnitMass>

    public init(
        id: UUID = UUID(),
        name: String,
        currentWeight: Measurement<UnitMass>,
        goalWeight: Measurement<UnitMass>
    ) {
        self.id = id
        self.name = name
        self.currentWeight = currentWeight
        self.goalWeight = goalWeight
    }
}
