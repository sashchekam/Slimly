import CompressFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу сжатия.
///
/// Шаги выбора, обработки и итога — общие для всех инструментов, поэтому
/// собственного кода у фичи ровно столько, сколько в ней своего: шторка
/// со степенью сжатия и сравнение «до / после».
public enum CompressFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService
    ) -> RouteResolver {
        RouteResolver(for: CompressRoute.self) { route, router in
            switch route {
            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        router: router,
                        // Степень сжатия — шторка поверх выбора: настройка
                        // одна, и ради неё уходить с экрана не стоит.
                        destination: { .present(CompressRoute.level(items: $0)) }
                    )
                )

            case let .level(items):
                LevelSheetView(viewModel: LevelSheetViewModel(items: items, router: router))

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        outcome: { CompressRoute.outcome($0) }
                    )
                )

            case let .outcome(outcome):
                OutcomeView(
                    viewModel: OutcomeViewModel(
                        outcome: outcome,
                        library: mediaLibrary,
                        router: router,
                        comparison: { CompressRoute.comparison($0) }
                    )
                )

            case let .comparison(result):
                ComparisonView(
                    viewModel: ComparisonViewModel(
                        result: result,
                        library: mediaLibrary,
                        router: router
                    )
                )
            }
        }
    }

    private static let pickerConfig = MediaPickerConfig(
        title: "Выбрать файлы",
        hint: "Фото и видео из галереи",
        footnote: "Больше файлов за раз — в Pro",
        kind: nil,
        limit: 5,
        noun: .file
    )
}
