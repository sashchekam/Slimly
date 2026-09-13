import Foundation
import OSLog
import RevenueCat

/// Поднять SDK покупок. Отдельным воркером, потому что «поднялся или нет»
/// решает состав сервисов: без ключа магазина нет, и узнать об этом надо
/// один раз на старте, а не на каждом открытии пейволла.
@MainActor
protocol PurchasesBootstrapping {
    /// `false` — SDK не сконфигурирован, обращаться к нему нельзя.
    func start() -> Bool
}

@MainActor
struct PurchasesBootstrap: PurchasesBootstrapping {
    /// Ключ лежит в своём файле рядом с `GoogleService-Info.plist` и в
    /// репозиторий не едет: он публичный, но привязан к чужому кабинету —
    /// клон проекта не должен ходить в чужой магазин.
    private static let configName = "RevenueCat-Info"
    private static let apiKeyField = "API_KEY"
    private static let logger = Logger(subsystem: "com.slimly", category: "purchases")

    /// Повторная конфигурация поднимает второй экземпляр SDK поверх первого,
    /// а `Purchases.shared` живёт один на процесс.
    private static var isStarted = false

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func start() -> Bool {
        guard !Self.isStarted else { return true }
        guard let key = apiKey() else {
            Self.logger.warning("\(Self.configName).plist не найден — покупки выключены")
            return false
        }

        Purchases.configure(withAPIKey: key)
        Self.isStarted = true
        return true
    }

    /// Пустая строка — это не ключ, а забытый файл-образец: с ней SDK ушёл бы
    /// в сеть и отвечал отказом на каждый запрос витрины.
    private func apiKey() -> String? {
        guard
            let path = bundle.path(forResource: Self.configName, ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path) as? [String: Any],
            let key = values[Self.apiKeyField] as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        return key
    }
}
