import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: Slimly.name,
    organizationName: Slimly.organization,
    settings: .settings(base: Slimly.baseSettings),
    targets: [
        .target(
            name: Slimly.name,
            destinations: Slimly.destinations,
            product: .app,
            bundleId: Slimly.bundleIdPrefix,
            deploymentTargets: Slimly.deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": ""],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                ],
                "CFBundleDisplayName": "Slimly",
                "CFBundleURLTypes": [
                    [
                        "CFBundleTypeRole": "Editor",
                        "CFBundleURLName": "\(Slimly.bundleIdPrefix).deeplink",
                        "CFBundleURLSchemes": ["slimly"],
                    ],
                ],
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: Module.validated.map(\.targetDependency),
            settings: .settings(base: Slimly.baseSettings)
        ),
    ] + Module.validated.map(Target.module)
)
