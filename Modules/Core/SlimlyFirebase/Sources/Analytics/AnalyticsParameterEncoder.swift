import Foundation
import SlimlyCore

/// Разложить параметры события в словарь, который понимает SDK.
protocol AnalyticsParameterEncoding: Sendable {
    func encoded(_ parameters: [String: AnalyticsValue]) -> [String: Any]?
}

/// Firebase принимает только строку, целое и дробное: флаг едет единицей
/// и нулём, длинная строка обрезается — иначе параметр отбрасывается целиком
/// вместе со своим значением.
struct AnalyticsParameterEncoder: AnalyticsParameterEncoding {
    private static let textLimit = 100

    private let names: any AnalyticsNameNormalizing

    init(names: any AnalyticsNameNormalizing = AnalyticsNameNormalizer()) {
        self.names = names
    }

    func encoded(_ parameters: [String: AnalyticsValue]) -> [String: Any]? {
        guard !parameters.isEmpty else { return nil }

        return parameters.reduce(into: [:]) { result, pair in
            result[names.normalized(pair.key)] = Self.encoded(pair.value)
        }
    }

    private static func encoded(_ value: AnalyticsValue) -> Any {
        switch value {
        case let .text(text): String(text.prefix(textLimit))
        case let .int(number): number
        case let .double(number): number
        case let .flag(flag): flag ? 1 : 0
        }
    }
}
