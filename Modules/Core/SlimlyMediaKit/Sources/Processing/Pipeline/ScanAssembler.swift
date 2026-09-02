import Foundation
import SlimlyCore

/// Сборка пачки снимков в один документ.
///
/// Скан идёт своей дорогой: из пачки снимков получается один документ,
/// а не файл на каждый файл, — и поштучная очередь для него не годится.
protocol ScanAssembling: Sendable {
    /// `nil` — работу отменили.
    func assemble(
        _ request: ProcessingRequest,
        mode: ScanMode,
        bounds: ScanBounds,
        progress: any ProgressReporting,
        simulatedFailure: String?
    ) async -> ProcessingOutcome?
}

struct ScanAssembler: ScanAssembling {
    /// Доля прогресса страницы, приходящаяся на её подготовку. Остаток —
    /// сборка PDF: она одна на весь документ, и до её конца ни одна
    /// страница по-настоящему не готова.
    private static let pagePreparationShare = 0.9

    private let library: any MediaLibrary
    private let pages: any ScanPageRendering
    private let documents: any DocumentWriting
    private let names: any DocumentNaming
    private let results: any ProcessingResultWriting

    init(
        library: any MediaLibrary,
        pages: any ScanPageRendering = ScanPageRenderer(),
        documents: any DocumentWriting = PDFDocumentWriter(),
        names: any DocumentNaming = ScanDocumentNamer(),
        results: any ProcessingResultWriting = ProcessingResultWriter()
    ) {
        self.library = library
        self.pages = pages
        self.documents = documents
        self.names = names
        self.results = results
    }

    /// Нечитаемый снимок документ не отменяет: соберём PDF из тех страниц,
    /// что получились, а про пропущенные скажем на экране итога.
    func assemble(
        _ request: ProcessingRequest,
        mode: ScanMode,
        bounds: ScanBounds,
        progress: any ProgressReporting,
        simulatedFailure: String?
    ) async -> ProcessingOutcome? {
        var prepared: [(item: MediaItem, page: ScannedPage)] = []
        var failures: [ProcessingFailure] = []

        for (index, item) in request.items.enumerated() {
            guard !Task.isCancelled else { return nil }

            if let simulatedFailure {
                failures.append(ProcessingFailure(item: item, message: simulatedFailure))
                progress.update(index: index, fraction: 1)
                continue
            }

            do {
                let page = try await preparePage(item, mode: mode, quad: bounds[item])
                prepared.append((item, page))
                progress.update(index: index, fraction: Self.pagePreparationShare)
            } catch is CancellationError {
                return nil
            } catch {
                failures.append(ProcessingFailure(item: item, message: error.processingMessage))
                progress.update(index: index, fraction: 1)
            }
        }

        guard let cover = prepared.first?.item else {
            return ProcessingOutcome(request: request, results: [], failures: failures)
        }

        do {
            let document = try await assembleDocument(prepared.map(\.page), cover: cover)
            for index in request.items.indices {
                progress.update(index: index, fraction: 1)
            }
            return ProcessingOutcome(request: request, results: [document], failures: failures)
        } catch {
            // Документ не собрался — значит, не вышло ни одной страницы:
            // по отдельности они никуда не сохраняются.
            let reason = error.processingMessage
            failures.append(
                contentsOf: prepared.map { ProcessingFailure(item: $0.item, message: reason) }
            )
            return ProcessingOutcome(request: request, results: [], failures: failures)
        }
    }

    private func preparePage(
        _ item: MediaItem,
        mode: ScanMode,
        quad: DocumentQuad?
    ) async throws -> ScannedPage {
        let source = try await library.exportOriginal(item)
        defer { try? FileManager.default.removeItem(at: source) }
        return try pages.page(at: source, mode: mode, quad: quad)
    }

    /// Документ ложится в «Файлы»: PDF в медиатеке не место, да iOS туда его
    /// и не примет.
    ///
    /// - Parameter cover: первая удавшаяся страница. Результат у скана один
    ///   на весь заказ, а ``ProcessingResult`` привязан к исходнику — берём
    ///   ту страницу, что открывается в PDF первой: её превью и увидят
    ///   в списке итога.
    private func assembleDocument(_ prepared: [ScannedPage], cover: MediaItem) async throws -> ProcessingResult {
        let name = names.name(at: .now)

        return try await results.write(named: name, for: cover, destination: .files) { file in
            try documents.write(
                pages: prepared,
                to: file,
                title: (name as NSString).deletingPathExtension
            )
        }
    }
}
