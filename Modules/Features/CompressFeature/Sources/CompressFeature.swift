import CompressFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу сжатия.
///
/// Шаги выбора, обработки, итога и просмотра — общие для всех инструментов,
/// поэтому собственного кода у фичи ровно столько, сколько в ней своего:
/// шторка со степенью сжатия.
public enum CompressFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        previewRenderer: any MediaPreviewRenderer,
        analytics: any AnalyticsService,
        viewers: MediaViewers
    ) -> RouteResolver {
        // Общая аналитика приложения складывается в два объекта: путь
        // обработки у инструментов один на всех, а степень сжатия — своя.
        let flow = FlowAnalytics(analytics: analytics, tool: .compress)
        let compress = CompressAnalytics(analytics: analytics)

        return RouteResolver(for: CompressRoute.self) { route, router in
            switch route {
            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        analytics: flow,
                        router: router,
                        // Степень сжатия — шторка поверх выбора: настройка
                        // одна, и ради неё уходить с экрана не стоит.
                        destination: { .present(CompressRoute.level(items: $0)) }
                    ),
                    player: viewers.player
                )

            case let .level(items):
                LevelSheetView(
                    viewModel: LevelSheetViewModel(
                        items: items,
                        analytics: compress,
                        router: router
                    )
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
                        analytics: flow,
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
                        service: processingService,
                        analytics: flow,
                        router: router,
                        preview: { .push(CompressRoute.preview($0)) }
                    )
                )

            case let .preview(result):
                ResultPreviewView(
                    viewModel: ResultPreviewViewModel(
                        result: result,
                        kind: .compression,
                        library: mediaLibrary,
                        previews: previewRenderer,
                        router: router
                    ),
                    viewer: viewers.file
                )
            }
        }
    }

    private static let pickerConfig = MediaPickerConfig(
        title: "Выбрать файлы",
        hint: "Фото и видео из галереи",
        kind: nil,
        limit: 5,
        noun: .file
    )
}
