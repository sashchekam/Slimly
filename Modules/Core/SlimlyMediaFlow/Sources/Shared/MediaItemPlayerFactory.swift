import SlimlyCore
import SwiftUI

/// Чем оживить превью файла медиатеки: ролик и живое фото умеют играть,
/// обычному снимку хватает кадра.
///
/// Как и `MediaFileViewerFactory`, вью собирает модуль системной обработки —
/// PhotoKit и AVKit знает только он, — а общий шаг получает их фабрикой.
/// `nil` в ответ значит «играть нечего»: превью остаётся миниатюрой.
public typealias MediaItemPlayerFactory = @MainActor (MediaItem) -> AnyView?
