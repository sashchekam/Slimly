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
                        destination: { .push(ScanRoute.format(items: $0)) }
                    ),
                    player: mediaPlayer
                )

            case let .format(items):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig,
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        run: { ScanRoute.run($0) }
                    )
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
    private static let formatConfig = FormatStepConfig(
        title: "Как собрать скан",
        note: """
        Границы листа находим сами, кадр выпрямляем, фон добиваем до белого. \
        Ч/б даёт самый чёткий текст, цвет нужен печатям и картинкам. \
        Документ ляжет в «Файлы» — оригиналы останутся в медиатеке.
        """,
        actionTitle: "Собрать скан",
        sourceFormat: "Фото",
        formats: ScanMode.allCases.map { MediaFormat(target: .document($0)) },
        noun: .page,
        showsSize: false,
        makeOperation: { .scan($0) }
    )
}
