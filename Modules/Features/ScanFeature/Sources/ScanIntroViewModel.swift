import Foundation
import Observation
import ScanFeatureInterface
import SlimlyNavigation

@MainActor
@Observable
public final class ScanIntroViewModel {
    private let router: Router

    public init(router: Router) {
        self.router = router
    }

    /// Камеры в проекте пока нет: съёмка ведёт в тот же выбор страниц.
    /// Отдельный маршрут появится вместе с `VNDocumentCameraViewController`,
    /// и поменяется только эта строка.
    public func openCamera() {
        router.push(ScanRoute.picker)
    }

    public func openGallery() {
        router.push(ScanRoute.picker)
    }

    public func goBack() {
        router.pop()
    }
}
