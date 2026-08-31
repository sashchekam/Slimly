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

    /// Камера показывается поверх флоу: у неё нет ни шапки, ни полей экрана,
    /// и в стеке она выглядела бы провалом в другое приложение.
    public func openCamera() {
        router.cover(ScanRoute.camera)
    }

    public func openGallery() {
        router.push(ScanRoute.picker)
    }

    public func goBack() {
        router.pop()
    }
}
