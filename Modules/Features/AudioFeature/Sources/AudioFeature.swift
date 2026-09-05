import AudioFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу «извлечь звук».
///
/// От конвертации отличается сутью, а не экранами: исходное видео остаётся
/// нетронутым, а дорожка становится отдельным файлом — поэтому здесь нет
/// предложения удалить оригиналы.
public enum AudioFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService,
        analytics: any AnalyticsService,
        viewers: MediaViewers
    ) -> RouteResolver {
        let flow = FlowAnalytics(analytics: analytics, tool: .audio)

        return RouteResolver(for: AudioRoute.self) { route, router in
            switch route {
            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        analytics: flow,
                        router: router,
                        destination: { .push(AudioRoute.format(items: $0)) }
                    ),
                    player: viewers.player
                )

            case let .format(items):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig,
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        preview: { .push(AudioRoute.sourcePreview($0)) },
                        run: { AudioRoute.run($0) }
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
                        analytics: flow,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        outcome: { AudioRoute.outcome($0) }
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
                        // Дорожку слушают шторкой поверх итога: уходить
                        // с экрана ради одной кнопки «играть» незачем.
                        preview: { .present(AudioRoute.preview($0)) }
                    )
                )

            case let .preview(result):
                AudioPreviewSheetView(
                    viewModel: AudioPreviewSheetViewModel(result: result, router: router),
                    viewer: viewers.file
                )
            }
        }
    }

    private static var pickerConfig: MediaPickerConfig {
        MediaPickerConfig(
            title: L10n.Tool.extractAudio,
            hint: L10n.Picker.hint,
            kind: .video,
            limit: 3,
            noun: .video
        )
    }

    /// MP3 в списке нет: кодировщика MP3 в iOS не существует, и предлагать
    /// его значило бы обещать то, чего система не умеет.
    private static var formatConfig: FormatStepConfig {
        FormatStepConfig(
            title: L10n.Format.title,
            note: L10n.Format.note,
            actionTitle: L10n.Tool.extractAudio,
            sourceFormat: L10n.Format.source,
            formats: [
                MediaFormat(target: .audio(.aac(kilobits: 128)), ratio: 0.03),
                MediaFormat(target: .audio(.aac(kilobits: 256)), ratio: 0.06),
                MediaFormat(target: .audio(.linearPCM), ratio: 0.35),
            ],
            noun: .video,
            makeOperation: { .extractAudio($0) }
        )
    }
}
