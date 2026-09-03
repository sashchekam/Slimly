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
                "NSCameraUsageDescription":
                    "Slimly включает камеру, чтобы снять страницы документа и собрать их в PDF.",
                "NSPhotoLibraryAddUsageDescription":
                    "Slimly сохраняет обработанные файлы в медиатеку — оригиналы остаются на месте.",
                // Извлечённые дорожки лежат в папке приложения: без этих двух
                // ключей она не видна в «Файлах», и забрать звук было бы нечем.
                "UIFileSharingEnabled": true,
                "LSSupportsOpeningDocumentsInPlace": true,
                "UIUserInterfaceStyle": "Dark",
                // Все экраны свёрстаны под вертикаль, а камера скана рассчитывает
                // на портретный кадр — поворот только ломает раскладку.
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                ],
                // На iPad портретной ориентации мало: без полноэкранного режима
                // система требует поддержки всех четырёх поворотов, потому что
                // в Split View окно можно развернуть как угодно.
                "UIRequiresFullScreen": true,
                // Быстрые действия в контекстном меню иконки: те же инструменты,
                // что и на главной. Список — в `Slimly.quickActions`.
                "UIApplicationShortcutItems": Slimly.quickActions,
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
            scripts: [Slimly.swiftLintScript],
            // Расширение с виджетами едет внутрь бандла приложения —
            // Tuist сам кладёт его в фазу «Embed App Extensions».
            dependencies: Module.validated.map(\.targetDependency)
                + [.target(name: Slimly.widgetName)],
            settings: .settings(base: Slimly.baseSettings)
        ),
        .slimlyWidget,
    ] + Module.validated.map(Target.module)
)
