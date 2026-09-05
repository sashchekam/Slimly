import ProjectDescription

public extension Slimly {
    static let widgetName = "SlimlyWidget"

    /// Виджету доступен только каталог инструментов и дизайн-система: он
    /// рисует ярлыки и никого не открывает сам — за него это делает адрес
    /// `slimly://`, который разберёт приложение. Фичи в расширение не едут.
    static let widgetModules: [Module] = [.shortcuts, .designSystem]
}

public extension Target {
    /// Расширение с виджетами.
    ///
    /// Живёт отдельным таргетом, а не внутри приложения: WidgetKit исполняет
    /// виджеты в собственном процессе, и вся их вёрстка обязана собираться
    /// без единого фичевого модуля.
    static let slimlyWidget: Target = .target(
        name: Slimly.widgetName,
        destinations: Slimly.destinations,
        product: .appExtension,
        bundleId: "\(Slimly.bundleIdPrefix).widget",
        deploymentTargets: Slimly.deploymentTargets,
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "Slimly",
            "NSExtension": [
                "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
            ],
        ]),
        sources: ["Widget/Sources/**"],
        // Расширение — отдельный бандл со своим языком: строки виджетов
        // и интента лежат здесь, а не в каталоге приложения.
        resources: ["Widget/Resources/**"],
        dependencies: Slimly.widgetModules.map(\.targetDependency),
        settings: .settings(base: Slimly.baseSettings)
    )
}
