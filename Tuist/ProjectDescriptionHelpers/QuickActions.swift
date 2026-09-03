import ProjectDescription

public extension Slimly {
    /// Быстрые действия в контекстном меню иконки — те же инструменты,
    /// что и на главном экране.
    ///
    /// Список повторяет каталог `ToolShortcut`, но собран заново: меню
    /// доступно сразу после установки, ещё до первого запуска, поэтому оно
    /// живёт в Info.plist, а манифест Tuist кода приложения не видит.
    /// Добавляя инструмент в каталог, добавь его и сюда.
    ///
    /// Система показывает не больше четырёх пунктов, поэтому порядок здесь
    /// не косметика: пятый в меню не попадёт.
    static let quickActions: Plist.Value = [
        quickAction(
            id: "compress",
            title: "Сжатие",
            subtitle: "Фото и видео",
            symbol: "arrow.down.right.and.arrow.up.left",
            url: "slimly://compress"
        ),
        quickAction(
            id: "convert-photo",
            title: "Конвертация фото",
            subtitle: "HEIC · JPEG · PNG",
            symbol: "photo.on.rectangle.angled",
            url: "slimly://convert/photo"
        ),
        quickAction(
            id: "convert-video",
            title: "Конвертация видео",
            subtitle: "MOV · MP4 · H.264 / HEVC",
            symbol: "film",
            url: "slimly://convert/video"
        ),
        quickAction(
            id: "scan",
            title: "Скан документа",
            subtitle: "Фото или камера → PDF",
            symbol: "doc.viewfinder",
            url: "slimly://scan"
        ),
        quickAction(
            id: "audio",
            title: "Извлечь звук",
            subtitle: "M4A или WAV из видео",
            symbol: "waveform",
            url: "slimly://audio"
        ),
    ]

    /// Пункт меню несёт свой `slimly://`-адрес: приложение открывает его той же
    /// таблицей ссылок, что и обычный диплинк, — отдельной ветки навигации
    /// для меню иконки нет.
    private static func quickAction(
        id: String,
        title: String,
        subtitle: String,
        symbol: String,
        url: String
    ) -> Plist.Value {
        [
            "UIApplicationShortcutItemType": .string("\(bundleIdPrefix).quickaction.\(id)"),
            "UIApplicationShortcutItemTitle": .string(title),
            "UIApplicationShortcutItemSubtitle": .string(subtitle),
            "UIApplicationShortcutItemIconSymbolName": .string(symbol),
            "UIApplicationShortcutItemUserInfo": ["url": .string(url)],
        ]
    }
}
