import UIKit

/// Мост между сценой UIKit и SwiftUI: быстрые действия приходят только
/// делегату сцены, SwiftUI-эквивалента у них нет. Единственная задача
/// делегата приложения — подставить свой класс делегата сцены; окно
/// по-прежнему создаёт SwiftUI.
final class QuickActionAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting session: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = QuickActionSceneDelegate.self
        return configuration
    }
}

/// Делегат нужен ровно за одним: поймать выбранное действие и положить
/// его в ящик. Навигацией занимается App-контейнер, как и для диплинков.
final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {
    /// Холодный старт: приложение запущено самим действием.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options: UIScene.ConnectionOptions
    ) {
        guard let item = options.shortcutItem else { return }
        QuickActionInbox.shared.accept(item)
    }

    /// Приложение уже было в памяти.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionInbox.shared.accept(shortcutItem)
        completionHandler(true)
    }
}
