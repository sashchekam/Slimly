import Foundation
import SlimlyCore

/// Сервисы, собранные поверх Firebase, — единственное, что модуль отдаёт
/// наружу. Сами типы SDK за границу не выходят: приложение получает
/// `any AnalyticsService` и `any RemoteConfigService` и про Firebase
/// не знает ничего.
///
/// Без `GoogleService-Info.plist` состав подменяется тихими заглушками:
/// сборка без ключей — это рабочая сборка без аналитики, а не упавшая.
public struct FirebaseServices: Sendable {
    public let analytics: any AnalyticsService
    public let remoteConfig: any RemoteConfigService

    /// Конфигурация SDK — работа главного потока: `FirebaseApp.configure()`
    /// поднимает подсистемы, часть которых завязана на жизненный цикл
    /// приложения.
    @MainActor
    public init() {
        self.init(bootstrap: FirebaseBootstrap())
    }

    /// Готовый состав — превью, тестам и сборке, которой аналитика не нужна.
    public init(analytics: any AnalyticsService, remoteConfig: any RemoteConfigService) {
        self.analytics = analytics
        self.remoteConfig = remoteConfig
    }

    /// Состав без SDK: события уходят в никуда, конфиг отдаёт умолчания.
    public static var disabled: FirebaseServices {
        FirebaseServices(analytics: NoAnalytics(), remoteConfig: LocalRemoteConfig())
    }

    @MainActor
    init(bootstrap: any FirebaseBootstrapping) {
        guard bootstrap.start() else {
            analytics = NoAnalytics()
            remoteConfig = LocalRemoteConfig()
            return
        }

        analytics = FirebaseAnalyticsService()
        remoteConfig = FirebaseRemoteConfigService()
    }
}
