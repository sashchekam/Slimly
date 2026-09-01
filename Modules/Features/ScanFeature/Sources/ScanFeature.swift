import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyMediaKit
import SlimlyNavigation

/// Точка сборки флоу скана документа.
///
/// Единственный инструмент с собственным первым шагом: у скана есть выбор
/// источника — камера или галерея, — а дальше начинается общий путь.
public enum ScanFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        mediaPlayer: @escaping MediaItemPlayerFactory
    ) -> RouteResolver {
        RouteResolver(for: ScanRoute.self) { route, router in
            switch route {
            case .intro:
                ScanIntroView(viewModel: ScanIntroViewModel(router: router))

            case .camera:
                ScanCameraView(
                    viewModel: ScanCameraViewModel(
                        camera: DocumentCameraSession(pageLimit: pageLimit),
                        pageLimit: pageLimit,
                        router: router
                    )
                )

            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        router: router,
                        destination: { .push(ScanRoute.pages(items: $0)) }
                    ),
                    player: mediaPlayer
                )

            case let .pages(items):
                ScanPagesView(
                    viewModel: ScanPagesViewModel(
                        items: items,
                        detector: boundsDetector,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        router: router
                    )
                )

            case let .format(items, bounds):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig(bounds: bounds),
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        preview: { .push(ScanRoute.sourcePreview($0)) },
                        run: { ScanRoute.run($0) }
                    )
                )

            case let .sourcePreview(item):
                SourcePreviewView(
                    viewModel: SourcePreviewViewModel(
                        item: item,
                        library: mediaLibrary,
                        // Вес страницы не показываем и здесь: в списке
                        // его нет, и в просмотре ему взяться неоткуда.
                        showsSize: false,
                        router: router
                    ),
                    player: mediaPlayer
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        outcome: { ScanRoute.outcome($0) }
                    )
                )

            case let .outcome(outcome):
                OutcomeView(
                    viewModel: OutcomeViewModel(
                        outcome: outcome,
                        library: mediaLibrary,
                        router: router,
                        // Документ уходит поверх всего: у системного
                        // просмотрщика своя полноэкранная жизнь с шапкой
                        // и кнопкой «Готово».
                        preview: { .cover(ScanRoute.preview($0)) }
                    )
                )

            case let .preview(result):
                if let url = result.outputURL {
                    SystemDocumentPreview(url: url) { router.dismiss() }
                        .ignoresSafeArea()
                        // Шапку рисует сам просмотрщик — пустая панель стека
                        // над ней стала бы вторым баром.
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }

    /// Поиск листа в снимке. Собирается здесь же, где и камера: это часть
    /// механики скана, а не общий сервис приложения — больше он никому
    /// не нужен.
    private static let boundsDetector = VisionDocumentBoundsDetector()

    /// Сколько страниц берём за раз — и в галерее, и с камеры.
    ///
    /// Предел один на оба источника: это ограничение документа, а не способа
    /// его набрать, и расходиться этим числам было бы неоткуда объяснить.
    static let pageLimit = 5

    private static let pickerConfig = MediaPickerConfig(
        title: "Страницы скана",
        hint: "Порядок страниц — как порядок выбора",
        kind: .photo,
        limit: pageLimit,
        noun: .page,
        // Страницу выбирают по тому, что на ней написано: вес снимка
        // здесь ни на что не влияет и в итог документа не переходит.
        showsSize: false
    )

    /// Режим — это вид страницы: у трёх вариантов одна и та же обработка,
    /// но разное количество цвета на выходе.
    ///
    /// Границы приезжают с предыдущего шага и уходят в задание: обработка
    /// не должна искать лист заново — рамку человек уже видел и принял.
    private static func formatConfig(bounds: ScanBounds) -> FormatStepConfig {
        FormatStepConfig(
            title: "Как собрать скан",
            note: """
            Кадр выпрямляем по выбранным границам, фон добиваем до белого. \
            Ч/б даёт самый чёткий текст, цвет нужен печатям и картинкам. \
            Документ ляжет в «Файлы» — оригиналы останутся в медиатеке.
            """,
            actionTitle: "Собрать скан",
            sourceFormat: "Фото",
            formats: ScanMode.allCases.map { MediaFormat(target: .document($0)) },
            noun: .page,
            showsSize: false,
            makeOperation: { .scan($0, bounds: bounds) }
        )
    }
}
