import ProjectDescription

public enum Slimly {
    public static let name = "Slimly"
    public static let organization = "com.slimly"
    public static let bundleIdPrefix = "com.slimly"
    public static let destinations: Destinations = .iOS
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")

    /// Общие для всех таргетов настройки компилятора.
    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.2",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
}
