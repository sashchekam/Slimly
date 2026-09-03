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
        // SwiftLint читает весь репозиторий, а песочница скриптов пускает
        // только к объявленным входам — со сборочной фазой линтера она
        // несовместима.
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        "DEVELOPMENT_TEAM": "LV77XK8TZC",
        // Рекомендации валидации проекта в Xcode 26. Кода на Objective-C у нас
        // нет, поэтому верификатор модулей ничего не проверяет, — но без него
        // Xcode на каждом открытии предлагает «Update to recommended settings»
        // и правит сгенерированный `.xcodeproj`, который тут же перезатирается.
        "ENABLE_MODULE_VERIFIER": "YES",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu17 gnu++20",
        // Строковых каталогов пока нет; настройка стоит заранее, чтобы первый
        // же `.xcstrings` сразу давал типобезопасные символы вместо строк.
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
        // Символы ассетов расширяют `Color` и `Image`: `Color(.launchBackground)`
        // вместо строкового имени, которое компилятор не проверяет.
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    ]

    /// Линтер на сборке приложения: правила общие для всех модулей, поэтому
    /// хватает одной фазы — она проходит по всему репозиторию.
    ///
    /// `--strict` поднимает предупреждения до ошибок: целевое состояние
    /// репозитория — ноль замечаний, а жёлтое предупреждение в логе сборки
    /// не замечают.
    ///
    /// Отсутствие SwiftLint сборку не валит: на чужой машине без него
    /// приложение всё равно должно собираться.
    /// Реестр событий аналитики собирается из кода, поэтому в сборке он
    /// только проверяется: разошёлся с `ANALYTICS.md` — сборка падает.
    ///
    /// Без этой фазы реестр устаревает молча, а вспоминают о нём ровно
    /// тогда, когда по нему настраивают отчёт.
    public static let analyticsRegistryScript: TargetScript = .pre(
        script: """
        # Xcode отдаёт фазе свой SDK — тот, которым собирается приложение.
        # Скрипт же запускается на маке, и с SDK симулятора компилятор
        # не находит даже стандартную библиотеку.
        export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

        swift "$SRCROOT/Tools/AnalyticsRegistry.swift" --check "$SRCROOT"
        """,
        name: "AnalyticsRegistry",
        basedOnDependencyAnalysis: false
    )

    public static let swiftLintScript: TargetScript = .pre(
        script: """
        # Xcode запускает фазы не из shell пользователя: в PATH нет ни
        # Homebrew, ни mise, и линтер «пропадает» на машине, где он есть.
        export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

        if command -v swiftlint >/dev/null; then
            swiftlint lint --strict --quiet --config "$SRCROOT/.swiftlint.yml" "$SRCROOT"
        else
            echo "warning: SwiftLint не установлен — brew install swiftlint"
        fi
        """,
        name: "SwiftLint",
        basedOnDependencyAnalysis: false
    )
}
