import Foundation
import Observation
import ScanFeatureInterface
import SlimlyNavigation

@MainActor
@Observable
public final class ScanIntroViewModel {
    /// Сколько страниц можно взять из галереи — про это написано в подсказке
    /// под кнопкой, поэтому число нужно самой шторке, а не только источнику.
    public let pageLimit: Int

    private let analytics: ScanAnalytics
    private let router: Router

    public init(pageLimit: Int, analytics: ScanAnalytics, router: Router) {
        self.pageLimit = pageLimit
        self.analytics = analytics
        self.router = router
    }

    /// Слой, который показал шторку: сам источник открывается уже в нём.
    /// Внутри шторки ни камере, ни галерее места нет — они не продолжение
    /// выбора, а замена ему.
    private var presenter: Router { router.parent ?? router }

    /// Камера показывается поверх флоу: у неё нет ни шапки, ни полей экрана,
    /// и в стеке она выглядела бы провалом в другое приложение.
    public func openCamera() {
        analytics.didPickSource(.camera)

        let presenter = presenter
        router.dismiss()
        presenter.cover(ScanRoute.camera)
    }

    public func openGallery() {
        analytics.didPickSource(.gallery)

        let presenter = presenter
        router.dismiss()
        presenter.push(ScanRoute.picker)
    }

    public func cancel() {
        router.dismiss()
    }
}
