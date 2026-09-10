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
        services: MediaFlowServices,
        analytics: any AnalyticsService,
        viewers: MediaViewers
    ) -> RouteResolver {
        // Путь обработки у скана общий с остальными инструментами, а съёмка
        // страниц и границы листа — только его: отсюда две аналитики.
        let flow = FlowAnalytics(analytics: analytics, tool: .scan)
        let scan = ScanAnalytics(analytics: analytics)

        return RouteResolver(for: ScanRoute.self) { route, router in
            switch route {
            case .intro:
                ScanIntroView(
                    viewModel: ScanIntroViewModel(
                        pageLimit: services.limits.scanPages,
                        analytics: scan,
                        router: router
                    )
                )

            case .camera:
                // Предел читается один раз на экран: съёмка и её подсказка
                // считают одни и те же страницы, и разъехаться этим числам
                // посреди набора документа нельзя.
                let pageLimit = services.limits.scanPages
                ScanCameraView(
                    viewModel: ScanCameraViewModel(
                        camera: DocumentCameraSession(pageLimit: pageLimit),
                        pageLimit: pageLimit,
                        analytics: scan,
                        router: router
                    )
                )

            case .picker:
                MediaPickerView(
                    viewModel: MediaPickerViewModel(
                        config: pickerConfig(limit: services.limits.scanPages),
                        library: services.library,
                        pro: services.pro,
                        analytics: flow,
                        router: router,
                        destination: { .push(ScanRoute.pages(items: $0)) }
                    ),
                    player: viewers.player
                )

            case let .pages(items):
                ScanPagesView(
                    viewModel: ScanPagesViewModel(
                        items: items,
                        detector: boundsDetector,
                        thumbnails: services.library.thumbnailLoader,
                        analytics: scan,
                        router: router
                    )
                )

            case let .format(items, bounds):
                FormatStepView(
                    viewModel: FormatStepViewModel(
                        config: formatConfig(bounds: bounds),
                        items: items,
                        router: router,
                        thumbnails: services.library.thumbnailLoader,
                        preview: { .push(ScanRoute.sourcePreview($0)) },
                        run: { ScanRoute.run($0) }
                    )
                )

            case let .sourcePreview(item):
                SourcePreviewView(
                    viewModel: SourcePreviewViewModel(
                        item: item,
                        library: services.library,
                        // Вес страницы не показываем и здесь: в списке
                        // его нет, и в просмотре ему взяться неоткуда.
                        showsSize: false,
                        router: router
                    ),
                    player: viewers.player
                )

            case let .run(request):
                ProcessingView(
                    viewModel: ProcessingViewModel(
                        request: request,
                        service: services.processing,
                        analytics: flow,
                        router: router,
                        thumbnails: services.library.thumbnailLoader,
                        outcome: { ScanRoute.outcome($0) }
                    )
                )

            case let .outcome(outcome):
                OutcomeView(
                    viewModel: OutcomeViewModel(
                        outcome: outcome,
                        library: services.library,
                        service: services.processing,
                        review: services.review,
                        analytics: flow,
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

    /// Поиск листа в снимке. Собирается здесь же, где и камера: это часть
    /// механики скана, а не общий сервис приложения — больше он никому
    /// не нужен.
    private static let boundsDetector = VisionDocumentBoundsDetector()

    private static func pickerConfig(limit: Int) -> MediaPickerConfig {
        MediaPickerConfig(
            title: L10n.Picker.title,
            hint: L10n.Picker.hint,
            kind: .photo,
            limit: limit,
            noun: .page,
            // Страницу выбирают по тому, что на ней написано: вес снимка
            // здесь ни на что не влияет и в итог документа не переходит.
            showsSize: false
        )
    }

    /// Режим — это вид страницы: у трёх вариантов одна и та же обработка,
    /// но разное количество цвета на выходе.
    ///
    /// Границы приезжают с предыдущего шага и уходят в задание: обработка
    /// не должна искать лист заново — рамку человек уже видел и принял.
    private static func formatConfig(bounds: ScanBounds) -> FormatStepConfig {
        FormatStepConfig(
            title: L10n.Format.title,
            note: { _ in L10n.Format.note },
            actionTitle: L10n.Format.action,
            sourceFormat: L10n.Format.source,
            formats: ScanMode.allCases.map { MediaFormat(target: .document($0)) },
            noun: .page,
            showsSize: false,
            makeOperation: { .scan($0, bounds: bounds) }
        )
    }
}
