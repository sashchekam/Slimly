import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Просмотр одного готового файла.
///
/// Экран общий для всех инструментов: различается только то, есть ли с чем
/// сравнивать. У сжатия меняется картинка при том же формате — там нужна
/// пара «оригинал / результат»; у конвертации и скана сравнивать нечего,
/// и остаётся один кадр результата.
@MainActor
@Observable
public final class ResultPreviewViewModel {
    public enum Side: String, Sendable {
        case before
        case after
    }

    public let result: ProcessingResult
    public var side: Side = .after

    /// Кадры держим данными, а не картинками: декодирование — дело View,
    /// а ViewModel не должна зависеть от SwiftUI.
    public private(set) var beforeData: Data?
    public private(set) var afterData: Data?
    /// Оригинал для плеера. Приезжает не сразу: у ролика из iCloud система
    /// сначала подкачает файл, и до этого на месте кадр.
    public private(set) var beforePlaybackURL: URL?

    private let kind: ProcessingKind
    private let library: any MediaLibrary
    /// Кадра нет у дорожки: там просмотр целиком рисует плеер, и
    /// рендерер такому инструменту передавать незачем.
    private let previews: (any MediaPreviewRenderer)?
    private let router: Router

    public init(
        result: ProcessingResult,
        kind: ProcessingKind,
        library: any MediaLibrary,
        previews: (any MediaPreviewRenderer)? = nil,
        router: Router
    ) {
        self.result = result
        self.kind = kind
        self.library = library
        self.previews = previews
        self.router = router
    }

    private var item: MediaItem { result.item }

    /// Пара «до / после» есть только там, где результат сопоставим
    /// с оригиналом по картинке.
    public var showsSides: Bool { FlowCopy.allowsComparison(kind) }

    /// Оригинал берём из медиатеки, результат — из файла: ассетом он ещё
    /// не стал, а если и стал, найти его по имени было бы гаданием.
    public func load() async {
        if showsSides {
            beforeData = await library.thumbnail(for: item, size: 420)
        }

        if let previews, let url = result.outputURL {
            afterData = await previews.preview(at: url, maxPixel: 1400)
        }

        // Ролик ищем последним: кадры уже на экране, а ссылка на оригинал
        // может ждать выкачки из iCloud.
        if showsSides, item.kind == .video {
            beforePlaybackURL = await library.playbackURL(for: item)
        }
    }

    /// Файл выбранной стороны — его и отдаём вьюеру. Годится ли формат
    /// для своего экрана, решает фабрика: здесь про AVKit и PDFKit не знают.
    public var viewerURL: URL? {
        isShowingAfter ? result.outputURL : beforePlaybackURL
    }

    /// Пропорции окна просмотра: у видео — кадр, у снимка — лист.
    public var previewAspectRatio: Double {
        item.kind == .video ? 16.0 / 9.0 : 3.0 / 4.0
    }

    public var currentData: Data? {
        isShowingAfter ? afterData : beforeData
    }

    /// В заголовке — имя готового файла: у конвертации и скана оно другое,
    /// и именно его пользователь будет искать в «Файлах».
    public var title: String { result.outputName }

    public var subtitle: String {
        // У дорожки своего кадра нет, и размер кадра исходника к ней
        // отношения не имеет: подписываем, откуда она и сколько длится.
        guard kind != .audioExtraction else {
            let time = item.duration.map(DurationFormatter.string) ?? ""
            return time.isEmpty ? "Дорожка видео" : "Дорожка видео · \(time)"
        }

        let size = item.pixelSizeText
        let meta = MediaItemFormatter.meta(item)
        return size.isEmpty
            ? "\(sourceKindWord) · \(meta)"
            : "\(sourceKindWord) · \(size) · \(meta)"
    }

    public var beforeText: String { FileSizeFormatter.string(bytes: item.byteCount) }

    public var afterText: String { FileSizeFormatter.string(bytes: result.outputByteCount) }

    public var deltaText: String { MediaItemFormatter.reduction(result) }

    /// Значок дельты уместен только у сжатия: у конвертации вес меняется
    /// как придётся, и «+140%» читалось бы как ошибка, а не как факт.
    public var showsDelta: Bool { kind == .compression }

    public var isShowingAfter: Bool { !showsSides || side == .after }

    /// Расширение готового файла: «PDF», «HEIC». Формат обработки в маршрут
    /// не приезжает, а имя файла его уже несёт.
    public var outputFormat: String {
        (result.outputName as NSString).pathExtension.uppercased()
    }

    // MARK: Подписи

    public var beforeTitle: String { "Оригинал · \(beforeText)" }

    public var afterTitle: String { "Сжатое · \(afterText)" }

    /// Пока кадр не приехал, подписываем, что именно грузится: пустая
    /// штриховка без подписи читалась бы как ошибка.
    public var placeholderLabel: String {
        guard isShowingAfter else { return "ОРИГИНАЛ" }
        return switch kind {
        case .compression: "СЖАТАЯ КОПИЯ"
        case .conversion: outputFormat.isEmpty ? "РЕЗУЛЬТАТ" : outputFormat
        case .scan: "ДОКУМЕНТ"
        case .audioExtraction: "ДОРОЖКА"
        }
    }

    public var chipText: String {
        guard isShowingAfter else { return "оригинал · \(beforeText)" }
        return kind == .compression
            ? "после · \(afterText)"
            : "\(outputFormat.lowercased()) · \(afterText)"
    }

    public var note: String {
        guard isShowingAfter else { return "Оригинал из медиатеки — для сравнения." }

        return switch kind {
        case .compression:
            "Копия из медиатеки, \(Int((result.reduction * 100).rounded()))% веса ушло. Оригинал не тронут."
        case .conversion:
            "Готовый \(outputFormat) из медиатеки. Оригинал остался как был."
        case .scan:
            "Готовый \(outputFormat) — он же лежит в «Файлах», в папке Slimly."
        case .audioExtraction:
            "Готовая дорожка — она лежит в «Файлах», в папке Slimly. Видео не изменялось."
        }
    }

    private var sourceKindWord: String {
        item.kind == .video ? "Видео" : "Фото"
    }

    public func goBack() {
        router.pop()
    }
}
