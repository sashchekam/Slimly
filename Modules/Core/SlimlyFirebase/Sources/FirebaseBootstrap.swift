import FirebaseCore
import Foundation
import OSLog

/// Поднять SDK. Отдельным воркером, потому что «поднялся или нет» решает
/// состав сервисов: без конфигурации ни аналитики, ни удалённого конфига
/// не будет, и узнать об этом надо один раз на старте.
@MainActor
protocol FirebaseBootstrapping {
    /// `false` — SDK не сконфигурирован, обращаться к нему нельзя.
    func start() -> Bool
}

@MainActor
struct FirebaseBootstrap: FirebaseBootstrapping {
    private static let configName = "GoogleService-Info"
    private static let logger = Logger(subsystem: "com.slimly", category: "firebase")

    /// Повторная конфигурация валит SDK, а `FirebaseApp` живёт один на процесс.
    ///
    /// Отметка своя, а не `FirebaseApp.app() == nil`: до конфигурации тот
    /// сам пишет в лог ошибку «default Firebase app has not yet been
    /// configured», и она всплывала бы в каждом запуске как настоящая.
    private static var isStarted = false

    func start() -> Bool {
        guard !Self.isStarted else { return true }

        // `FirebaseApp.configure()` без файла конфигурации падает с
        // `fatalError`. Клон репозитория и сборка на чужой машине не должны
        // разбиваться о недостающий файл — приложение просто работает
        // без аналитики.
        guard Bundle.main.path(forResource: Self.configName, ofType: "plist") != nil else {
            Self.logger.warning("\(Self.configName).plist не найден — Firebase выключен")
            return false
        }

        FirebaseApp.configure()
        Self.isStarted = true
        return true
    }
}
