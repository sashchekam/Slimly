import Foundation
import ProjectDescription

/// Единый реестр модулей приложения.
///
/// Правила связей (архитектура B, см. ARCHITECTURE.md):
/// - core-модули не знают ничего о фичах;
/// - фича зависит от core-модулей и от `*Interface`-модулей чужих фич,
///   но никогда — от их реализации;
/// - `*Interface` — тонкий модуль без UI: только маршруты и публичные контракты.
public enum Module: CaseIterable {
    // Core
    case core
    case designSystem
    case navigation
    // Features
    case welcomeInterface
    case welcome
    case homeInterface
    case home

    public enum Kind {
        case core
        case featureInterface
        case feature
    }

    public var kind: Kind {
        switch self {
        case .core, .designSystem, .navigation: .core
        case .welcomeInterface, .homeInterface: .featureInterface
        case .welcome, .home: .feature
        }
    }

    public var name: String {
        switch self {
        case .core: "SlimlyCore"
        case .designSystem: "SlimlyDesignSystem"
        case .navigation: "SlimlyNavigation"
        case .welcomeInterface: "WelcomeFeatureInterface"
        case .welcome: "WelcomeFeature"
        case .homeInterface: "HomeFeatureInterface"
        case .home: "HomeFeature"
        }
    }

    /// Папка модуля на диске.
    public var path: String {
        switch self {
        case .core, .designSystem, .navigation:
            "Modules/Core/\(name)"
        case .welcomeInterface, .welcome:
            "Modules/Features/WelcomeFeature"
        case .homeInterface, .home:
            "Modules/Features/HomeFeature"
        }
    }

    /// Исходники: у фичи — `Sources`, у её интерфейса — `Interface`.
    public var sourcesPath: String {
        switch kind {
        case .core, .feature: "\(path)/Sources"
        case .featureInterface: "\(path)/Interface"
        }
    }

    public var dependencies: [Module] {
        switch self {
        case .core: []
        case .designSystem: [.core]
        case .navigation: [.core]
        case .welcomeInterface: [.navigation]
        case .welcome: [.core, .designSystem, .navigation, .welcomeInterface, .homeInterface]
        case .homeInterface: [.navigation]
        case .home: [.core, .designSystem, .navigation, .homeInterface, .welcomeInterface]
        }
    }

    public var targetDependency: TargetDependency { .target(name: name) }

    /// Все модули, проверенные на соблюдение правил связей.
    /// Нарушение валит `tuist generate` с внятным сообщением.
    public static var validated: [Module] {
        for module in allCases {
            for dependency in module.dependencies {
                guard isAllowed(from: module, to: dependency) else {
                    fatalError(
                        """
                        Запрещённая зависимость: \(module.name) → \(dependency.name).
                        Core не может знать о фичах, а фича — о реализации чужой фичи
                        (только о её *Interface-модуле).
                        """
                    )
                }
            }
        }
        return allCases
    }

    private static func isAllowed(from module: Module, to dependency: Module) -> Bool {
        switch (module.kind, dependency.kind) {
        case (.core, .core):
            true
        case (.featureInterface, .core):
            true
        case (.feature, .core), (.feature, .featureInterface):
            true
        default:
            false
        }
    }
}

public extension Target {
    /// Динамический фреймворк-модуль по общему шаблону.
    static func module(_ module: Module) -> Target {
        .target(
            name: module.name,
            destinations: Slimly.destinations,
            product: .framework,
            bundleId: "\(Slimly.bundleIdPrefix).\(module.name.lowercased())",
            deploymentTargets: Slimly.deploymentTargets,
            sources: ["\(module.sourcesPath)/**"],
            resources: resourcesIfExist(at: "\(module.path)/Resources"),
            dependencies: module.dependencies.map(\.targetDependency),
            settings: .settings(base: Slimly.baseSettings)
        )
    }

    private static func resourcesIfExist(at path: String) -> ResourceFileElements? {
        FileManager.default.fileExists(atPath: path) ? ["\(path)/**"] : nil
    }
}
