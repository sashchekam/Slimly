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
    case mediaKit
    case mediaFlow
    // Features
    case homeInterface
    case home
    case compressInterface
    case compress
    case convertInterface
    case convert
    case audioInterface
    case audio
    case scanInterface
    case scan
    case profileInterface
    case profile

    public enum Kind {
        case core
        case featureInterface
        case feature
    }

    public var kind: Kind {
        switch self {
        case .core, .designSystem, .navigation, .mediaKit, .mediaFlow: .core
        case .homeInterface, .compressInterface, .convertInterface,
             .audioInterface, .scanInterface, .profileInterface: .featureInterface
        case .home, .compress, .convert, .audio, .scan, .profile: .feature
        }
    }

    public var name: String {
        switch self {
        case .core: "SlimlyCore"
        case .designSystem: "SlimlyDesignSystem"
        case .navigation: "SlimlyNavigation"
        case .mediaKit: "SlimlyMediaKit"
        case .mediaFlow: "SlimlyMediaFlow"
        case .homeInterface: "HomeFeatureInterface"
        case .home: "HomeFeature"
        case .compressInterface: "CompressFeatureInterface"
        case .compress: "CompressFeature"
        case .convertInterface: "ConvertFeatureInterface"
        case .convert: "ConvertFeature"
        case .audioInterface: "AudioFeatureInterface"
        case .audio: "AudioFeature"
        case .scanInterface: "ScanFeatureInterface"
        case .scan: "ScanFeature"
        case .profileInterface: "ProfileFeatureInterface"
        case .profile: "ProfileFeature"
        }
    }

    /// Папка модуля на диске.
    public var path: String {
        switch self {
        case .core, .designSystem, .navigation, .mediaKit, .mediaFlow:
            "Modules/Core/\(name)"
        case .homeInterface, .home:
            "Modules/Features/HomeFeature"
        case .compressInterface, .compress:
            "Modules/Features/CompressFeature"
        case .convertInterface, .convert:
            "Modules/Features/ConvertFeature"
        case .audioInterface, .audio:
            "Modules/Features/AudioFeature"
        case .scanInterface, .scan:
            "Modules/Features/ScanFeature"
        case .profileInterface, .profile:
            "Modules/Features/ProfileFeature"
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
        // Единственный модуль, который знает про PhotoKit и AVFoundation:
        // всё общение с системой собрано здесь, а не размазано по фичам.
        case .mediaKit: [.core]
        // Общие шаги флоу — это экраны, поэтому нужны и дизайн-система,
        // и роутер: шаг сам решает, куда положить следующий маршрут.
        case .mediaFlow: [.core, .designSystem, .navigation]
        case .homeInterface: [.navigation]
        case .home: [.core, .designSystem, .navigation, .homeInterface]
        // Маршруты инструментов несут модели медиатеки и задание
        // на обработку, поэтому их интерфейсам нужен core.
        case .compressInterface: [.core, .navigation]
        // Сравнение «до / после» показывает кадр из уже готового файла,
        // а его умеет достать только модуль системной обработки.
        case .compress: [.core, .designSystem, .navigation, .mediaKit, .mediaFlow, .compressInterface]
        case .convertInterface: [.core, .navigation]
        case .convert: [.core, .designSystem, .navigation, .mediaFlow, .convertInterface]
        case .audioInterface: [.core, .navigation]
        case .audio: [.core, .designSystem, .navigation, .mediaFlow, .audioInterface]
        case .scanInterface: [.core, .navigation]
        case .scan: [.core, .designSystem, .navigation, .mediaFlow, .scanInterface]
        case .profileInterface: [.navigation]
        case .profile: [.core, .designSystem, .navigation, .profileInterface]
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
