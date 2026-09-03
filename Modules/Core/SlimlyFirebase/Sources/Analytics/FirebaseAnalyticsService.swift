import FirebaseAnalytics
import Foundation
import SlimlyCore

/// Общая аналитика приложения на Firebase.
///
/// Всё, что она делает, — чинит имена и раскладывает параметры: очередь,
/// пакетную отправку и повторы держит SDK.
public struct FirebaseAnalyticsService: AnalyticsService {
    private let names: any AnalyticsNameNormalizing
    private let parameters: any AnalyticsParameterEncoding

    public init() {
        self.init(names: AnalyticsNameNormalizer(), parameters: AnalyticsParameterEncoder())
    }

    init(names: any AnalyticsNameNormalizing, parameters: any AnalyticsParameterEncoding) {
        self.names = names
        self.parameters = parameters
    }

    public func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(names.normalized(event.name), parameters: parameters.encoded(event.parameters))
    }

    public func set(_ property: AnalyticsUserProperty, to value: String?) {
        Analytics.setUserProperty(value, forName: names.normalized(property.name))
    }
}
