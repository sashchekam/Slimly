import Foundation
import SlimlyCore
import SlimlyDesignSystem

/// Инструмент, каким его видят точки входа снаружи главного экрана: виджеты,
/// меню иконки, будущие App Shortcuts.
///
/// Маршрута здесь нет и быть не может — снаружи процесса приложения открывать
/// нечего. Вместо него адрес `slimly://`, который на входе разберёт та же
/// таблица диплинков, что и обычную ссылку.
public struct ToolShortcut: Identifiable, Hashable, Sendable {
    /// Идентификатор — перечисление, а не строка: по нему App раздаёт
    /// маршруты, и новый инструмент в каталоге сразу валит сборку там,
    /// где его забыли открыть.
    public enum ID: String, CaseIterable, Sendable {
        case compress
        case convertPhoto = "convert-photo"
        case convertVideo = "convert-video"
        case scan
        case audio
    }

    public let id: ID
    public let title: String
    /// Имя для тесных мест — ряда иконок в виджете, где полное не помещается.
    public let short: String
    public let subtitle: String
    public let icon: SlimlyIcon.Kind
    public let url: URL

    init(
        id: ID,
        title: String,
        short: String,
        subtitle: String,
        icon: SlimlyIcon.Kind,
        path: String
    ) {
        self.id = id
        self.title = title
        self.short = short
        self.subtitle = subtitle
        self.icon = icon
        url = Self.address(path)
    }

    /// Адрес собирается из констант каталога, поэтому разбор не падает.
    /// На невозможной ветке отдаём заведомо чужой адрес: приложение по нему
    /// просто откроется с главного экрана, а не упадёт вместе с виджетом.
    private static func address(_ path: String) -> URL {
        URL(string: "\(DeeplinkURL.scheme)://\(path)") ?? URL(fileURLWithPath: "/")
    }
}
