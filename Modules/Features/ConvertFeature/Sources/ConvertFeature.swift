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
        fileViewer: @escaping MediaFileViewerFactory,
        mediaPlayer: @escaping MediaItemPlayerFactory
    ) -> RouteResolver {
        RouteResolver(for: ConvertRoute.self) { route, router in
            switch route {
            case let .picker(kind):
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig(kind),
                        library: mediaLibrary,
                        router: router,
                        destination: { .push(ConvertRoute.format(kind: kind, items: $0)) }
                    ),
                    player: mediaPlayer
                )

            case let .format(kind, items):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig(kind, items: items),
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        run: { ConvertRoute.run($0) }
                    )
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
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
                    viewer: fileViewer
                )
            }
        }
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
