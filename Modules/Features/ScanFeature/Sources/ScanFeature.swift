import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу скана документа.
///
/// Единственный инструмент с собственным первым шагом: у скана есть выбор
/// источника — камера или галерея, — а дальше начинается общий путь.
public enum ScanFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService
    ) -> RouteResolver {
        RouteResolver(for: ScanRoute.self) { route, router in
            switch route {
            case .intro:
                ScanIntroView(viewModel: ScanIntroViewModel(router: router))

            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        router: router,
                        destination: { .push(ScanRoute.format(items: $0)) }
                    )
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
                        router: router
                    )
                )
            }
        }
    }

    private static let pickerConfig = MediaPickerConfig(
        title: "Страницы скана",
        hint: "Порядок страниц — как порядок выбора",
        footnote: "Выпрямление и чистка фона — автоматически",
        kind: .photo,
        limit: 5,
        noun: .page
    )

    /// Режим — это и вид страницы, и её вес: у трёх вариантов одна и та же
    /// обработка, но разное количество цвета на выходе.
    private static let formatConfig = FormatStepConfig(
        title: "Как собрать скан",
        note: """
        Границы листа находим сами, кадр выпрямляем, фон добиваем до белого. \
        Ч/б даёт самый лёгкий файл и самый чёткий текст, цвет нужен печатям \
        и картинкам. Документ ляжет в «Файлы» — оригиналы останутся в медиатеке.
        """,
        actionTitle: "Собрать скан",
        sourceFormat: "Фото",
        formats: ScanMode.allCases.map {
            MediaFormat(target: .document($0), ratio: $0.estimatedRatio)
        },
        noun: .page,
        makeOperation: { .scan($0) }
    )
}
