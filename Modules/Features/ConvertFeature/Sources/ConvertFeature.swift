import ConvertFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу конвертации фото и видео.
public enum ConvertFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        previewRenderer: any MediaPreviewRenderer,
        analytics: any AnalyticsService,
        viewers: MediaViewers
    ) -> RouteResolver {
        RouteResolver(for: ConvertRoute.self) { route, router in
            switch route {
            case let .picker(kind):
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig(kind),
                        library: mediaLibrary,
                        analytics: FlowAnalytics(analytics: analytics, tool: tool(for: kind)),
                        router: router,
                        destination: { .push(ConvertRoute.format(kind: kind, items: $0)) }
                    ),
                    player: viewers.player
                )

            case let .format(kind, items):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig(kind, items: items),
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        preview: { .push(ConvertRoute.sourcePreview($0)) },
                        run: { ConvertRoute.run($0) }
                    )
                )

            case let .sourcePreview(item):
                SourcePreviewView(
                    viewModel: SourcePreviewViewModel(
                        item: item,
                        library: mediaLibrary,
                        router: router
                    ),
                    viewer: viewers.file,
                    player: viewers.player
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
                        analytics: FlowAnalytics(analytics: analytics, tool: tool(for: request)),
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        outcome: { ConvertRoute.outcome($0) }
                    )
                )

            case let .outcome(outcome):
                OutcomeView(
                    viewModel: OutcomeViewModel(
                        outcome: outcome,
                        library: mediaLibrary,
                        service: processingService,
                        analytics: FlowAnalytics(analytics: analytics, tool: tool(for: outcome.request)),
                        router: router,
                        preview: { .push(ConvertRoute.preview($0)) }
                    )
                )

            case let .preview(result):
                ResultPreviewView(
                    viewModel: ResultPreviewViewModel(
                        result: result,
                        kind: .conversion,
                        library: mediaLibrary,
                        previews: previewRenderer,
                        router: router
                    ),
                    viewer: viewers.file
                )
            }
        }
    }

    // MARK: Инструмент для аналитики

    /// Фото и видео в отчёте разъезжаются на два инструмента: экраны у них
    /// общие, а привычки разные.
    private static func tool(for kind: ConvertKind) -> FlowTool {
        kind == .photo ? .convertPhoto : .convertVideo
    }

    /// Последние шаги флоу вида уже не несут — маршрут там носит задание.
    /// Что именно конвертировали, видно по файлам этого задания.
    private static func tool(for request: ProcessingRequest) -> FlowTool {
        request.items.first?.kind == .video ? .convertVideo : .convertPhoto
    }

    // MARK: Настройки шагов

    private static func pickerConfig(_ kind: ConvertKind) -> MediaPickerConfig {
        switch kind {
        case .photo:
            MediaPickerConfig(
                title: "Конвертация фото",
                hint: "Формат зададим на следующем шаге",
                kind: .photo,
                limit: 5,
                noun: .photo
            )
        case .video:
            MediaPickerConfig(
                title: "Конвертация видео",
                hint: "Контейнер и кодек на следующем шаге",
                kind: .video,
                limit: 3,
                noun: .video
            )
        }
    }

    private static func formatConfig(_ kind: ConvertKind, items: [MediaItem]) -> FormatStepConfig {
        switch kind {
        case .photo:
            FormatStepConfig(
                title: "В какой формат",
                note: """
                HEIC весит меньше, JPEG совместим со всем. PNG — без потерь, \
                но тяжелее оригинала. Исходный формат в списке не показываем.
                """,
                actionTitle: "Конвертировать",
                // Формат исходников берём по факту выбора: один HEIC среди
                // JPEG уже делает всю пачку «съёмкой iPhone».
                sourceFormat: items.contains(where: \.isHEIC) ? "HEIC" : "JPEG",
                // WebP в списке нет: ImageIO на iOS его читает, но не пишет.
                formats: [
                    MediaFormat(target: .image(.jpeg), ratio: 0.95),
                    MediaFormat(target: .image(.heic), ratio: 0.55),
                    MediaFormat(target: .image(.png), ratio: 2.4),
                ],
                noun: .photo,
                makeOperation: { .convert($0) }
            )

        case .video:
            FormatStepConfig(
                title: "Контейнер и кодек",
                note: """
                HEVC даёт меньший вес, H.264 открывается везде. \
                Перекодирование, не смена расширения.
                """,
                actionTitle: "Конвертировать",
                sourceFormat: sourceContainer(of: items),
                formats: [
                    MediaFormat(target: .video(container: .mp4, codec: .h264), ratio: 1.05),
                    MediaFormat(target: .video(container: .mp4, codec: .hevc), ratio: 0.6),
                    MediaFormat(target: .video(container: .mov, codec: .hevc), ratio: 0.62),
                ],
                noun: .video,
                makeOperation: { .convert($0) }
            )
        }
    }

    /// Кодек исходника до чтения файла неизвестен, поэтому в паре «из → в»
    /// показываем только контейнер — то, что видно по имени файла.
    private static func sourceContainer(of items: [MediaItem]) -> String {
        let extensions = Set(items.map(\.fileExtension))
        guard extensions.count == 1, let single = extensions.first, !single.isEmpty else {
            return "Видео"
        }
        return single.uppercased()
    }
}
