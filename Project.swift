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
                // Экран запуска — сплошная заливка цветом фона: белая вспышка
                // между иконкой и заставкой ломает всё впечатление от старта.
                "UILaunchScreen": ["UIColorName": "LaunchBackground"],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                ],
                "CFBundleDisplayName": "Slimly",
                "NSPhotoLibraryUsageDescription":
                    "Slimly показывает медиатеку, чтобы вы выбрали файлы для сжатия и конвертации.",
                "NSPhotoLibraryAddUsageDescription":
                    "Slimly сохраняет обработанные файлы в медиатеку — оригиналы остаются на месте.",
                // Извлечённые дорожки лежат в папке приложения: без этих двух
                // ключей она не видна в «Файлах», и забрать звук было бы нечем.
                "UIFileSharingEnabled": true,
                "LSSupportsOpeningDocumentsInPlace": true,
                "UIUserInterfaceStyle": "Dark",
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
