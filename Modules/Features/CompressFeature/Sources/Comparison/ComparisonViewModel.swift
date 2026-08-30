import Foundation
import Observation
import SlimlyCore
import SlimlyMediaKit
import SlimlyNavigation

@MainActor
@Observable
public final class ComparisonViewModel {
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

    private let library: any MediaLibrary
    private let router: Router

    public init(result: ProcessingResult, library: any MediaLibrary, router: Router) {
        self.result = result
        self.library = library
        self.router = router
    }

    private var item: MediaItem { result.item }

    /// Оригинал берём из медиатеки, результат — из файла: ассетом он ещё
    /// не стал, а если и стал, найти его по имени было бы гаданием.
    public func load() async {
        beforeData = await library.thumbnail(for: item, size: 420)

        if let url = result.outputURL {
            afterData = await MediaPreview.image(at: url, maxPixel: 1400)
        }
    }

    public var currentData: Data? {
        isShowingAfter ? afterData : beforeData
    }

    public var title: String { item.fileName }

    public var subtitle: String {
        let kind = item.kind == .video ? "Видео" : "Фото"
        let size = item.pixelSizeText
        return size.isEmpty
            ? "\(kind) · \(MediaItemFormatter.meta(item))"
            : "\(kind) · \(size) · \(MediaItemFormatter.meta(item))"
    }

    public var beforeText: String { FileSizeFormatter.string(bytes: item.byteCount) }

    public var afterText: String { FileSizeFormatter.string(bytes: result.outputByteCount) }

    public var deltaText: String { MediaItemFormatter.reduction(result) }

    public var isShowingAfter: Bool { side == .after }

    /// Пока кадр не приехал, подписываем, что именно грузится: пустая
    /// штриховка без подписи читалась бы как ошибка.
    public var placeholderLabel: String {
        isShowingAfter ? "СЖАТАЯ КОПИЯ" : "ОРИГИНАЛ"
    }

    public var chipText: String {
        isShowingAfter ? "после · \(afterText)" : "оригинал · \(beforeText)"
    }

    public var note: String {
        guard isShowingAfter else { return "Оригинал из медиатеки — для сравнения." }
        let percent = Int((result.reduction * 100).rounded())
        return "Копия из медиатеки, \(percent)% веса ушло. Оригинал не тронут."
    }

    public func goBack() {
        router.pop()
    }
}
