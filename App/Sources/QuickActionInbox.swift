import Observation
import SlimlyCore
import UIKit

/// Ящик для быстрого действия, выбранного в контекстном меню иконки.
///
/// Действие несёт `slimly://`-адрес, поэтому дальше оно ничем не отличается
/// от обычного диплинка: ящик только разбирает адрес и придерживает его
/// до появления сцены SwiftUI — при холодном старте действие приходит
/// раньше, чем SwiftUI успевает о нём спросить.
///
/// Экземпляр один на приложение, и это вынужденно: делегата сцены создаёт
/// UIKit по имени класса, внедрить в него зависимость параметром некуда.
@MainActor
@Observable
final class QuickActionInbox {
    static let shared = QuickActionInbox()

    private(set) var pending: DeeplinkURL?

    private init() { }

    func accept(_ item: UIApplicationShortcutItem) {
        guard
            let address = item.userInfo?["url"] as? String,
            let url = URL(string: address),
            let deeplink = DeeplinkURL(url: url)
        else { return }
        pending = deeplink
    }

    /// Забрать адрес и очистить ящик: одно нажатие открывает экран один раз.
    func take() -> DeeplinkURL? {
        defer { pending = nil }
        return pending
    }
}
