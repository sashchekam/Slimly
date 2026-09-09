import ConvertFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу конвертации фото и видео.
public enum ConvertFeature {
    @MainActor
    public static func resolver(
        services: MediaFlowServices,
        previewRenderer: any MediaPreviewRenderer,
        analytics: any AnalyticsService,
        viewers: MediaViewers
    ) -> RouteResolver {
        RouteResolver(for: ConvertRoute.self) { route, router in
            switch route {
            case let .picker(kind):
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig(kind, limit: limit(kind, services.limits)),
                        library: services.library,
                        pro: services.pro,
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
                        thumbnails: services.library.thumbnailLoader,
                        preview: { .push(ConvertRoute.sourcePreview($0)) },
                        run: { ConvertRoute.run($0) }
                    )
                )

            case let .sourcePreview(item):
                SourcePreviewView(
                    viewModel: SourcePreviewViewModel(
                        item: item,
                        library: services.library,
                        router: router
                    ),
                    viewer: viewers.file,
                    player: viewers.player
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: services.processing,
                        analytics: FlowAnalytics(analytics: analytics, tool: tool(for: request)),
                        router: router,
                        thumbnails: services.library.thumbnailLoader,
                        outcome: { ConvertRoute.outcome($0) }
                    )
                )

            case let .outcome(outcome):
                OutcomeView(
                    viewModel: OutcomeViewModel(
                        outcome: outcome,
                        library: services.library,
                        service: services.processing,
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
                        library: services.library,
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

    private static func pickerConfig(_ kind: ConvertKind, limit: Int) -> MediaPickerConfig {
        switch kind {
        case .photo:
            MediaPickerConfig(
                title: L10n.Photo.title,
                hint: L10n.Photo.hint,
                kind: .photo,
                limit: limit,
                noun: .photo
            )
        case .video:
            MediaPickerConfig(
                title: L10n.Video.title,
                hint: L10n.Video.hint,
                kind: .video,
                limit: limit,
                noun: .video
            )
        }
    }

    private static func limit(_ kind: ConvertKind, _ limits: MediaFlowLimits) -> Int {
        kind == .photo ? limits.convertPhotos : limits.convertVideos
    }

    private static func formatConfig(_ kind: ConvertKind, items: [MediaItem]) -> FormatStepConfig {
        switch kind {
        case .photo:
            FormatStepConfig(
                title: L10n.PhotoFormat.title,
                note: { _ in L10n.PhotoFormat.note },
                actionTitle: L10n.Common.action,
                sourceFormat: sourceFormat(
                    of: items.map { photoFormat(of: $0) },
                    fallback: L10n.PhotoFormat.source
                ),
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
                title: L10n.VideoFormat.title,
                note: { videoNote(for: $0) },
                actionTitle: L10n.Common.action,
                // Кодек исходника до чтения файла неизвестен, поэтому в паре
                // «из → в» показываем только контейнер — то, что видно
                // по имени файла.
                sourceFormat: sourceFormat(
                    of: items.map { $0.fileExtension.uppercased() },
                    fallback: L10n.VideoFormat.source
                ),
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

    /// Подпись под списком форматов видео.
    ///
    /// Выбирают здесь не расширение, а размен «откроется везде» на «весит
    /// меньше», — поэтому про выбранный формат написано, что он даёт и где
    /// подведёт. Хвост общий: контейнер здесь не переклеивают, файл
    /// пересобирают заново, и знать это стоит при любом выборе.
    private static func videoNote(for format: MediaFormat) -> String {
        let about = switch format.target {
        case .video(container: .mp4, codec: .h264): L10n.VideoNote.mp4H264
        case .video(container: .mp4, codec: .hevc): L10n.VideoNote.mp4Hevc
        case .video(container: .mov, codec: .hevc): L10n.VideoNote.movHevc
        // Прочих пар в списке нет — для них хватит общего хвоста.
        default: ""
        }

        guard !about.isEmpty else { return L10n.VideoFormat.note }
        return "\(about) \(L10n.VideoFormat.note)"
    }

    /// Формат исходников — левая половина пары «из → в».
    ///
    /// Берём по факту выбора: пока формат у всех файлов один, показываем его.
    /// Разошлись — общего формата у пачки нет, и вместо выдуманного ставим
    /// слово, которое верно всегда.
    private static func sourceFormat(of names: [String], fallback: String) -> String {
        let unique = Set(names.filter { !$0.isEmpty })
        guard unique.count == 1, let single = unique.first else { return fallback }
        return single
    }

    /// Формат снимка по его файлу.
    ///
    /// Имя здесь то же, каким формат подписан в списке целей: по нему шаг
    /// исходный формат из списка и убирает. Расширение как есть не годится —
    /// у файла оно `jpg`, а формат зовётся JPEG, и «JPG → JPEG» выглядело бы
    /// как настоящий выбор. HEIC узнаём ещё и по флагу медиатеки: у снимка
    /// с камеры расширение бывает `heif`, а формат тот же.
    private static func photoFormat(of item: MediaItem) -> String {
        guard !item.isHEIC else { return ImageFormat.heic.displayName }

        return switch item.fileExtension {
        case "jpg", "jpeg": ImageFormat.jpeg.displayName
        case "png": ImageFormat.png.displayName
        default: item.fileExtension.uppercased()
        }
    }
}
