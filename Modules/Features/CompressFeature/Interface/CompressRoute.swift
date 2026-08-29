import SlimlyCore
import SlimlyNavigation

/// Публичный вход в фичу сжатия.
///
/// Маршруты несут данные шага, а не ссылку на общий объект сессии: так
/// состояние потока целиком лежит в `Router`, и любую точку флоу можно
/// восстановить одним присвоением — из теста, из диплинка, из ресторации.
public enum CompressRoute: Route {
    /// Выбор файлов — корень таба.
    case gallery
    /// Пресет и переключатели для уже выбранных файлов.
    case setup(items: [MediaItem], options: CompressionOptions)
    case run(items: [MediaItem], options: CompressionOptions)
    case result(CompressionOutcome)
}
