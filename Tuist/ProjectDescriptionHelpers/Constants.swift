import ProjectDescription

public enum Slimly {
    public static let name = "Slimly"
    public static let organization = "com.slimly"
    public static let bundleIdPrefix = "com.slimly"
    public static let destinations: Destinations = .iOS
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")

    /// Общие для всех таргетов настройки.
    ///
    /// Команда подписи живёт здесь, а не в Xcode: `.xcodeproj` — генерируемый
    /// артефакт, и выставленная руками команда пропадает на первом же
    /// `tuist generate`. Достаётся она и модулям — фреймворки уезжают внутрь
    /// бандла и подписываются вместе с приложением.
    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.2",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "DEVELOPMENT_TEAM": "LV77XK8TZC",
    ]
}
