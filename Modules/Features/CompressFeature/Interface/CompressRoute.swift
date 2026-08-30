import SlimlyCore
import SlimlyNavigation

/// Публичный вход во флоу сжатия.
///
/// Маршруты несут данные шага, а не ссылку на общий объект сессии: так
/// состояние потока целиком лежит в `Router`, и любую точку флоу можно
/// восстановить одним присвоением — из теста, из диплинка, из ресторации.
public enum CompressRoute: Route {
    /// Выбор файлов — вход во флоу.
    case picker
    /// Степень сжатия для уже выбранных файлов.
    case level(items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
    /// Сравнение «до / после» одного файла.
    case comparison(ProcessingResult)
}
