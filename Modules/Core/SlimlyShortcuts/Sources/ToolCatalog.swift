/// Каталог инструментов — один список на все точки входа: хаб на главной,
/// виджеты и меню иконки. Порядок здесь и есть порядок карточек на главной.
///
/// Адреса совпадают с таблицей диплинков в App: инструмент открывается ссылкой,
/// а не отдельной веткой навигации на каждую точку входа.
public extension ToolShortcut {
    static let compress = ToolShortcut(
        id: .compress,
        title: "Сжатие",
        short: "Сжатие",
        subtitle: "Фото и видео",
        icon: .compress,
        path: "compress"
    )

    static let convertPhoto = ToolShortcut(
        id: .convertPhoto,
        title: "Конвертация фото",
        short: "Фото",
        subtitle: "HEIC · JPEG · PNG",
        icon: .photoConvert,
        path: "convert/photo"
    )

    static let convertVideo = ToolShortcut(
        id: .convertVideo,
        title: "Конвертация видео",
        short: "Видео",
        subtitle: "MOV · MP4 · H.264 / HEVC",
        icon: .videoConvert,
        path: "convert/video"
    )

    static let scan = ToolShortcut(
        id: .scan,
        title: "Скан документа",
        short: "Скан",
        subtitle: "Фото или камера → PDF",
        icon: .scan,
        path: "scan"
    )

    static let audio = ToolShortcut(
        id: .audio,
        title: "Извлечь звук",
        short: "Звук",
        subtitle: "M4A или WAV из видео",
        icon: .audio,
        path: "audio"
    )

    /// Список собран руками, а не из `ID.allCases`: порядок инструментов —
    /// решение макета, и алфавит идентификаторов ему не указ.
    static let all: [ToolShortcut] = [compress, convertPhoto, convertVideo, scan, audio]

    /// Чем виджет заполнен, пока инструмент в настройке не выбран.
    static let `default`: ToolShortcut = compress

    /// Инструмент по идентификатору: настройка виджета хранит строку,
    /// а не значение перечисления.
    static func named(_ identifier: String) -> ToolShortcut? {
        all.first { $0.id.rawValue == identifier }
    }
}
