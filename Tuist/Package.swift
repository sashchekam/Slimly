// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    // Зависимости собираются статически и уезжают внутрь того единственного
    // фреймворка, который их линкует (`SlimlyFirebase`, `SlimlyPurchases`):
    // динамическими их пришлось бы ещё и встраивать в бандл, и подписывать.
    productTypes: [:],
    baseSettings: .settings(base: [
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        "DEVELOPMENT_TEAM": "LV77XK8TZC",
    ])
)
#endif

let package = Package(
    name: "SlimlyDependencies",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "12.18.0")),
        .package(url: "https://github.com/RevenueCat/purchases-ios", .upToNextMajor(from: "5.0.0")),
    ]
)
