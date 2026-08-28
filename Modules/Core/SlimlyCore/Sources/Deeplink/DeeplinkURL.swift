import Foundation

/// Разобранный диплинк вида `slimly://welcome?source=push`.
///
/// Слой намеренно «глупый»: он ничего не знает про экраны и роуты —
/// маппинг в навигацию живёт в App (composition root).
public struct DeeplinkURL: Sendable, Equatable {
    public static let scheme = "slimly"

    public let host: String
    public let pathComponents: [String]
    public let queryItems: [String: String]

    public init?(url: URL) {
        guard
            url.scheme?.lowercased() == Self.scheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host, !host.isEmpty
        else { return nil }

        self.host = host
        pathComponents = components.path.split(separator: "/").map(String.init)
        queryItems = Dictionary(
            (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            },
            uniquingKeysWith: { _, last in last }
        )
    }

    public subscript(query key: String) -> String? { queryItems[key] }
}
