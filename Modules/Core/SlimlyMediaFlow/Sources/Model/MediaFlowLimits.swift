import SlimlyCore

/// Сколько файлов инструмент берёт за раз — все пределы тарифа разом.
///
/// Пределы лежат вместе и приезжают одним объектом, потому что правят их
/// тоже вместе: у скана пять страниц, у роликов три, и осмысленно это число
/// только рядом с соседними. Тарифов два, и у каждого свой ключ в консоли —
/// `media_limits` и `media_limits_pro`.
///
/// Умолчания здесь — бесплатный тариф, у Pro они в ``pro``: без сети,
/// без Firebase и до первой загрузки приложение всё равно должно знать,
/// сколько файлов брать, и знать это по тарифу.
public struct MediaFlowLimits: Sendable {
    /// Файлов за раз в сжатии. Предел бесплатной обработки подбирается
    /// по нагрузке и по тому, сколько человек доводит пачку до конца, —
    /// то есть после выпуска сборки, а не в ней.
    public var compressFiles: Int

    /// Снимков за раз в конвертации.
    public var convertPhotos: Int

    /// Роликов за раз в конвертации: у видео предел свой по той же причине,
    /// по какой у него свои форматы — пачка снимков обрабатывается быстрее
    /// пачки роликов.
    public var convertVideos: Int

    /// Роликов за раз в извлечении дорожки: дорожку вынимают из видео,
    /// и вес пачки здесь совсем другой.
    public var audioVideos: Int

    /// Страниц в документе — и из галереи, и с камеры.
    ///
    /// Предел один на оба источника: это ограничение документа, а не способа
    /// его набрать, и расходиться этим числам было бы неоткуда объяснить.
    public var scanPages: Int

    public init(
        compressFiles: Int = 1,
        convertPhotos: Int = 1,
        convertVideos: Int = 1,
        audioVideos: Int = 1,
        scanPages: Int = 1
    ) {
        self.compressFiles = compressFiles
        self.convertPhotos = convertPhotos
        self.convertVideos = convertVideos
        self.audioVideos = audioVideos
        self.scanPages = scanPages
    }

    /// Пределы Slimly Pro, пока их не прислал конфиг.
    ///
    /// Они не «бесплатные, умноженные на что-то»: сколько именно даёт
    /// подписка — вопрос цены, и меняться эти числа будут отдельно
    /// от бесплатных, потому и лежат отдельно.
    public static var pro: MediaFlowLimits {
        MediaFlowLimits(
            compressFiles: 10,
            convertPhotos: 10,
            convertVideos: 10,
            audioVideos: 10,
            scanPages: 25
        )
    }

    /// Поверх тарифа ложится то, что задано в конфиге, — только заданное.
    /// Объект в консоли правят по одному полю, и остальные должны остаться
    /// такими, какими их задал тариф.
    func applying(_ overlay: MediaLimitsOverlay) -> MediaFlowLimits {
        MediaFlowLimits(
            compressFiles: overlay.compressFiles ?? compressFiles,
            convertPhotos: overlay.convertPhotos ?? convertPhotos,
            convertVideos: overlay.convertVideos ?? convertVideos,
            audioVideos: overlay.audioVideos ?? audioVideos,
            scanPages: overlay.scanPages ?? scanPages
        )
    }
}
