import AudioFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Точка сборки флоу «извлечь звук».
///
/// От конвертации отличается сутью, а не экранами: исходное видео остаётся
/// нетронутым, а дорожка сохраняется отдельным файлом — поэтому здесь нет
/// предложения удалить оригиналы.
public enum AudioFeature {
    @MainActor
    public static func resolver(
        mediaLibrary: any MediaLibrary,
        processingService: any MediaProcessingService
    ) -> RouteResolver {
        RouteResolver(for: AudioRoute.self) { route, router in
            switch route {
            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig,
                        library: mediaLibrary,
                        router: router,
                        destination: { .push(AudioRoute.format(items: $0)) }
                    )
                )

            case let .format(items):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig,
                        items: items,
                        router: router,
                        thumbnails: mediaLibrary.thumbnailLoader,
                        run: { AudioRoute.run($0) }
                    )
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: processingService,
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
                        router: router
                    )
                )
            }
        }
    }

    private static let pickerConfig = MediaPickerConfig(
        title: "Извлечь звук",
        hint: "Дорожку сохраним отдельным файлом",
        footnote: "Видео остаётся без изменений",
        kind: .video,
        limit: 3,
        noun: .video
    )

    /// MP3 в списке нет: кодировщика MP3 в iOS не существует, и предлагать
    /// его значило бы обещать то, чего система не умеет.
    private static let formatConfig = FormatStepConfig(
        title: "Формат дорожки",
        note: "M4A — родной для iOS, WAV без потерь, но тяжёлый. Видео не меняем.",
        actionTitle: "Извлечь звук",
        sourceFormat: "Дорожка видео",
        formats: [
            MediaFormat(target: .audio(.aac(kilobits: 128)), ratio: 0.03),
            MediaFormat(target: .audio(.aac(kilobits: 256)), ratio: 0.06),
            MediaFormat(target: .audio(.linearPCM), ratio: 0.35),
        ],
        noun: .video,
        makeOperation: { .extractAudio($0) }
    )
}
