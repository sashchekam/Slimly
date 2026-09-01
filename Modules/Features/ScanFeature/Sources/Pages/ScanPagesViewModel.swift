import CoreGraphics
import Foundation
import Observation
import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaFlow
import SlimlyNavigation

/// Шаг «границы страниц» — единственное место, где человек может не согласиться
/// с автоматикой.
///
/// Раньше границы находились молча уже во время сборки: рамку никто не видел,
/// и косой кадр обнаруживался только в готовом PDF. Теперь то же самое
/// происходит до обработки и на виду — согласиться можно одним «Далее»,
/// а поправить углы можно у любой страницы.
@MainActor
@Observable
public final class ScanPagesViewModel {
    /// Страница со своими границами.
    ///
    /// Кадр держим данными: декодирование — дело View, а модель от SwiftUI
    /// не зависит.
    public struct Page: Identifiable, Sendable {
        public let item: MediaItem
        public fileprivate(set) var imageData: Data?
        /// Что нашла автоматика. `nil` — листа в кадре не видно.
        public fileprivate(set) var detected: DocumentQuad?
        /// Рамка, которая сейчас на экране.
        public fileprivate(set) var quad: DocumentQuad = .full
        /// Углы двигали руками — «Авто» вернёт найденное.
        public fileprivate(set) var isManual = false
        /// Кадр загружен и границы уже искали.
        public fileprivate(set) var isReady = false

        public var id: String { item.id }
    }

    public private(set) var pages: [Page]
    /// Какая страница открыта крупно.
    public private(set) var index = 0

    private let detector: any DocumentBoundsDetector
    private let thumbnailLoader: MediaThumbnailLoader
    private let router: Router

    /// Сторона кадра, который просим у медиатеки. Границы ищем в нём же,
    /// а не в оригинале: рамка должна обещать ровно то, что видно на экране.
    private static let previewSide = 1400

    public init(
        items: [MediaItem],
        detector: any DocumentBoundsDetector,
        thumbnails: @escaping MediaThumbnailLoader,
        router: Router
    ) {
        pages = items.map { Page(item: $0) }
        self.detector = detector
        thumbnailLoader = thumbnails
        self.router = router
    }

    public var thumbnails: MediaThumbnailLoader { thumbnailLoader }

    // MARK: Загрузка

    /// Кадры и границы идут по очереди, а не разом: страниц не больше пяти,
    /// зато каждая — полновесная сегментация, и параллельно они только
    /// отнимали бы друг у друга процессор.
    public func load() async {
        for position in pages.indices {
            guard !Task.isCancelled else { return }
            guard !pages[position].isReady else { continue }

            let item = pages[position].item
            let data = await thumbnailLoader(item, Self.previewSide)
            var detected: DocumentQuad?
            if let data {
                detected = await detector.bounds(in: data)
            }

            // Пока грузили, страницу могли и убрать — ищем её заново.
            guard let current = pages.firstIndex(where: { $0.id == item.id }) else { continue }
            pages[current].imageData = data
            pages[current].detected = detected
            // Ничего не нашли — рамка по краю кадра: она честно говорит,
            // что обрезать нечего, и её сразу можно потянуть за угол.
            if !pages[current].isManual {
                pages[current].quad = detected ?? .full
            }
            pages[current].isReady = true
        }
    }

    // MARK: Состояние

    public var page: Page { pages[index] }

    public var hasMultiplePages: Bool { pages.count > 1 }

    public func select(_ position: Int) {
        guard pages.indices.contains(position) else { return }
        index = position
    }

    public func isCurrent(_ page: Page) -> Bool { page.id == self.page.id }

    // MARK: Правка

    /// Перетаскивание угла. Рамку, сложившуюся бантиком, не принимаем —
    /// точка просто не доезжает, а палец продолжает вести.
    public func move(_ corner: DocumentQuad.Corner, to point: CGPoint) {
        guard let moved = page.quad.moving(corner, to: point) else { return }
        pages[index].quad = moved
        pages[index].isManual = true
    }

    /// Вернуть найденное автоматикой.
    public func resetToDetected() {
        guard let detected = page.detected else { return }
        pages[index].quad = detected
        pages[index].isManual = false
    }

    /// Взять кадр целиком — для страницы, которую обрезать не нужно.
    public func useWholeFrame() {
        pages[index].quad = .full
        pages[index].isManual = true
    }

    public var canResetToDetected: Bool {
        guard let detected = page.detected else { return false }
        return page.quad != detected
    }

    public var canUseWholeFrame: Bool { page.quad != .full }

    // MARK: Подписи

    public var title: String { "Границы страниц" }

    /// «Страница 2 из 3» — или просто состояние, когда страница одна.
    public var subtitle: String {
        guard hasMultiplePages else { return status }
        return "Страница \(index + 1) из \(pages.count) · \(status)"
    }

    private var status: String {
        if !page.isReady { return "ищем лист" }
        if page.isManual { return "рамка поправлена" }
        return page.detected == nil ? "лист не нашёлся" : "лист найден"
    }

    /// Подсказка под кадром. Говорит про рамку, а не про кнопки: человек
    /// смотрит на страницу, а не на интерфейс.
    public var hint: String {
        if !page.isReady {
            return "Ищем границы листа…"
        }
        if page.detected == nil, !page.isManual {
            return "Границы не нашлись — потяните углы по краю страницы"
        }
        return "Потяните за углы, если рамка легла мимо края"
    }

    public var ctaTitle: String {
        "Далее · \(CountFormatter.string(pages.count, .page))"
    }

    // MARK: Навигация

    public func goBack() {
        router.pop()
    }

    /// Дальше идёт общий шаг формата, а границы едут с ним: обработке нужны
    /// именно те рамки, что человек видел.
    ///
    /// В таблицу попадают только показанные границы. Страница, у которой
    /// автоматика ничего не нашла и которую не трогали руками, идёт без них —
    /// пусть обработка попробует найти лист сама, в полном разрешении.
    public func proceed() {
        var bounds = ScanBounds()
        for page in pages where page.isReady && (page.isManual || page.detected != nil) {
            bounds[page.id] = page.quad
        }
        router.push(ScanRoute.format(items: pages.map(\.item), bounds: bounds))
    }
}
