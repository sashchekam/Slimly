import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: Slimly.name,
    organizationName: Slimly.organization,
    // Язык разработки — английский: на нём написаны ключи строковых каталогов,
    // и он же достаётся тому, чьего языка среди переводов не нашлось.
    options: .options(developmentRegion: "en"),
    settings: .settings(base: Slimly.baseSettings),
    targets: [
        .target(
            name: Slimly.name,
            destinations: Slimly.destinations,
            product: .app,
            bundleId: Slimly.bundleIdPrefix,
            deploymentTargets: Slimly.deploymentTargets,
            infoPlist: .extendingDefault(with: [
                // Экран запуска повторяет первый кадр заставки: та же заливка
                // и тот же знак в центре. Заставка подхватывает его как есть,
                // поэтому вместо белой вспышки и второго проявления знака
                // с системного экрана сразу начинается анимация.
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                ],
                // Имя длиннее иконочной подписи: домашний экран покажет
                // «Slimly: Compr…», зато в поиске и настройках видно, что
                // приложение и сжимает, и сканирует.
                "CFBundleDisplayName": "Slimly: Compress & Scan",
                // Значения здесь — ключи и одновременно английский текст:
                // переводы лежат в `App/Resources/InfoPlist.xcstrings`.
                "NSPhotoLibraryUsageDescription":
                    "Slimly shows your photo library so you can pick files to compress and convert.",
                "NSCameraUsageDescription":
                    "Slimly uses the camera to shoot document pages and assemble them into a PDF.",
                "NSPhotoLibraryAddUsageDescription":
                    "Slimly saves processed files to your photo library — the originals stay where they are.",
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
            scripts: [Slimly.swiftLintScript, Slimly.analyticsRegistryScript, Slimly.l10nGeneratorScript],
            // Расширение с виджетами едет внутрь бандла приложения —
            // Tuist сам кладёт его в фазу «Embed App Extensions».
            dependencies: Module.validated.map(\.targetDependency)
                + [.target(name: Slimly.widgetName)],
            settings: .settings(base: Slimly.baseSettings)
        ),
        .slimlyWidget,
    ] + Module.validated.map(Target.module)
)
