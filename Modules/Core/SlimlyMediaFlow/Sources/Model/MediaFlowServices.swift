import SlimlyCore
import SlimlyNavigation

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

    /// Правило, по которому просят оценку. Момент у всех инструментов один
    /// и тот же — удачное сохранение, — а счётчик показов общий: три сжатия
    /// и три скана для человека одинаково значат, что приложение прижилось.
    public let review: any ReviewPrompting

    /// Куда ведёт предложение тарифа в шаге выбора файлов. Приходит готовым
    /// маршрутом, а не типом: пейволл — это фича, а модуль общих шагов
    /// про фичи ничего не знает. `nil` — предложение не показываем.
    public let paywall: (any Route)?

    @MainActor
    public init(
        library: any MediaLibrary,
        processing: any MediaProcessingService,
        remoteConfig: any RemoteConfigService,
        pro: any ProSubscription = NoProSubscription(),
        review: any ReviewPrompting = NoReviewPrompt(),
        paywall: (any Route)? = nil
    ) {
        self.library = library
        self.processing = processing
        self.remoteConfig = remoteConfig
        self.pro = pro
        self.review = review
        self.paywall = paywall
    }

    /// Пределы того тарифа, который сейчас у пользователя: умолчания тарифа,
    /// а поверх них — то, что задано в конфиге.
    ///
    /// Читают их на построении экрана, а не при сборке резолвера: и свежий
    /// конфиг приезжает уже после старта, и подписку могут оформить, пока
    /// приложение открыто.
    @MainActor public var limits: MediaFlowLimits {
        guard pro.isActive else {
            return MediaFlowLimits().applying(remoteConfig.value(for: .mediaLimits))
        }

        return MediaFlowLimits.pro.applying(remoteConfig.value(for: .mediaLimitsPro))
    }
}
