import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Просмотр исходного файла — того, что ещё только предстоит обработать.
///
/// Нужен до обработки, а не после: на шаге выбора формата от файла остаются
/// имя и миниатюра в 33 пункта, и по ним не всегда видно, тот ли это кадр.
/// От ``ResultPreviewViewModel`` отличается тем, что сравнивать здесь не с чем:
/// результата ещё нет, есть только оригинал.
@MainActor
@Observable
public final class SourcePreviewViewModel {
    public let item: MediaItem

    /// Кадр держим данными, а не картинкой: декодирование — дело View,
    /// а ViewModel не должна зависеть от SwiftUI.
    public private(set) var imageData: Data?
    /// Ссылка на оригинал для плеера. Приезжает не сразу: ролик из iCloud
    /// система сначала подкачает, и до этого на месте кадр.
    public private(set) var playbackURL: URL?

    private let library: any MediaLibrary
    /// Показывать ли вес: у скана он ни на что не влияет, как и в списке.
    private let showsSize: Bool
    private let router: Router

    public init(
        item: MediaItem,
        library: any MediaLibrary,
        showsSize: Bool = true,
        router: Router
    ) {
        self.item = item
        self.library = library
        self.showsSize = showsSize
        self.router = router
    }

    /// Кадр просим крупный: миниатюра списка на весь экран рассыпалась бы
    /// в пиксели, а оригинал целиком ради просмотра тянуть незачем.
    public func load() async {
        if imageData == nil {
            imageData = await library.thumbnail(for: item, size: 1400)
        }

        // Ролик ищем последним: кадр уже на экране, а ссылка на оригинал
        // может ждать выкачки из iCloud.
        guard item.kind == .video, playbackURL == nil else { return }
        playbackURL = await library.playbackURL(for: item)
    }

    public var title: String { item.fileName }

    /// «Фото · 4032 × 3024 · 3,1 МБ» — пустые части выпадают, если система
    /// не сообщила размер кадра или инструменту не нужен вес.
    public var subtitle: String {
        [
            MediaItemFormatter.kindLabel(item),
            item.pixelSizeText,
            MediaItemFormatter.meta(item, showsSize: showsSize),
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    /// Пропорции окна просмотра: у кадра известного размера — его
    /// собственные, иначе лист для снимка и кадр для ролика.
    public var previewAspectRatio: Double {
        guard item.pixelWidth > 0, item.pixelHeight > 0 else {
            return item.kind == .video ? 16.0 / 9.0 : 3.0 / 4.0
        }
        return Double(item.pixelWidth) / Double(item.pixelHeight)
    }

    /// Пока кадр не приехал, подписываем, что именно грузится: пустая
    /// штриховка без подписи читалась бы как ошибка.
    public var placeholderLabel: String {
        item.kind == .video ? "ВИДЕО" : "ОРИГИНАЛ"
    }

    public var note: String {
        "Оригинал из медиатеки — так он выглядит сейчас. Обработка его не меняет: результат станет отдельным файлом."
    }

    public func goBack() {
        router.pop()
    }
}
