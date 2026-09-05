/// Каталог инструментов — один список на все точки входа: хаб на главной,
/// виджеты и меню иконки. Порядок здесь и есть порядок карточек на главной.
///
/// Адреса совпадают с таблицей диплинков в App: инструмент открывается ссылкой,
/// а не отдельной веткой навигации на каждую точку входа.
///
/// Подписи собираются на каждом обращении к списку, а не один раз за запуск:
/// язык в приложении меняют на ходу, и сохранённый снимок остался бы
/// на прежнем.
public extension ToolShortcut {
    static var compress: ToolShortcut {
        ToolShortcut(
            id: .compress,
            title: L10n.Compress.title,
            short: L10n.Compress.title,
            subtitle: L10n.Compress.subtitle,
            icon: .compress,
            path: "compress"
        )
    }

    static var convertPhoto: ToolShortcut {
        ToolShortcut(
            id: .convertPhoto,
            title: L10n.Photo.title,
            short: L10n.Photo.short,
            subtitle: "HEIC · JPEG · PNG",
            icon: .photoConvert,
            path: "convert/photo"
        )
    }

    static var convertVideo: ToolShortcut {
        ToolShortcut(
            id: .convertVideo,
            title: L10n.Video.title,
            short: L10n.Video.short,
            subtitle: "MOV · MP4 · H.264 / HEVC",
            icon: .videoConvert,
            path: "convert/video"
        )
    }

    static var scan: ToolShortcut {
        ToolShortcut(
            id: .scan,
            title: L10n.Scan.title,
            short: L10n.Scan.short,
            subtitle: L10n.Scan.subtitle,
            icon: .scan,
            path: "scan"
        )
    }

    static var audio: ToolShortcut {
        ToolShortcut(
            id: .audio,
            title: L10n.Audio.title,
            short: L10n.Audio.short,
            subtitle: L10n.Audio.subtitle,
            icon: .audio,
            path: "audio"
        )
    }

    /// Список собран руками, а не из `ID.allCases`: порядок инструментов —
    /// решение макета, и алфавит идентификаторов ему не указ.
    static var all: [ToolShortcut] { [compress, convertPhoto, convertVideo, scan, audio] }

    /// Чем виджет заполнен, пока инструмент в настройке не выбран.
    static var `default`: ToolShortcut { compress }

    /// Инструмент по идентификатору: настройка виджета хранит строку,
    /// а не значение перечисления.
    static func named(_ identifier: String) -> ToolShortcut? {
        all.first { $0.id.rawValue == identifier }
    }
}
