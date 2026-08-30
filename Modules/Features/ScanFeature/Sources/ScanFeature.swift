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

    /// Сборки PDF ещё нет: экраны флоу на месте, а обработчик у скана
    /// пока не реализован — и он честно об этом сообщает на итоге.
    private static let formatConfig = FormatStepConfig(
        title: "Формат скана",
        note: "Сборка PDF пока в разработке — файлы останутся без изменений.",
        actionTitle: "Собрать скан",
        sourceFormat: "Фото со страницей",
        formats: [MediaFormat(target: .document, ratio: 0.18)],
        noun: .page,
        makeOperation: { .scan($0) }
    )
}
