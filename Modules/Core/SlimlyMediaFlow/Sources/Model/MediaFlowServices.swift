import SlimlyCore

/// Сервисы, из которых собирается любой инструмент.
///
/// Шаги у инструментов общие — значит, и нужно им одно и то же: медиатека
/// с исходниками, обработчик и значения, которыми управляют без выпуска
/// сборки. Поэтому они ездят одним значением, а не тремя параметрами,
/// повторёнными в каждом резолвере.
public struct MediaFlowServices {
    public let library: any MediaLibrary
    public let processing: any MediaProcessingService
    public let remoteConfig: any RemoteConfigService

    /// Тариф. У подписчика пределы свои, и приезжают они своим ключом:
    /// инструмент об этом не знает — он спрашивает `limits`.
    public let pro: any ProSubscription

    public init(
        library: any MediaLibrary,
        processing: any MediaProcessingService,
        remoteConfig: any RemoteConfigService,
        pro: any ProSubscription = NoProSubscription()
    ) {
        self.library = library
        self.processing = processing
        self.remoteConfig = remoteConfig
        self.pro = pro
    }

    /// Пределы того тарифа, который сейчас у пользователя: умолчания тарифа,
    /// а поверх них — то, что задано в конфиге.
    ///
    /// Читают их на построении экрана, а не при сборке резолвера: и свежий
    /// конфиг приезжает уже после старта, и подписку могут оформить, пока
    /// приложение открыто.
    public var limits: MediaFlowLimits {
        guard pro.isActive else {
            return MediaFlowLimits().applying(remoteConfig.value(for: .mediaLimits))
        }

        return MediaFlowLimits.pro.applying(remoteConfig.value(for: .mediaLimitsPro))
    }
}
