import Foundation
import Observation
import ScanFeatureInterface
import SlimlyCore
import SlimlyMediaKit
import SlimlyNavigation

@MainActor
@Observable
public final class ScanCameraViewModel {
    /// Камера отдана вью целиком: превью — системный слой, и пересказывать
    /// её состояние по одному свойству значило бы дублировать всю сессию.
    public let camera: DocumentCameraSession

    public private(set) var toast: String?

    private let pageLimit: Int
    private let analytics: ScanAnalytics
    private let router: Router

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    public init(
        camera: DocumentCameraSession,
        pageLimit: Int,
        analytics: ScanAnalytics,
        router: Router
    ) {
        self.camera = camera
        self.pageLimit = pageLimit
        self.analytics = analytics
        self.router = router

        camera.onAutomaticShot = { [weak self] in
            self?.reportShot()
        }
    }

    // MARK: Жизненный цикл

    public func appear() async {
        await camera.start()
        reportFailure()
    }

    public func disappear() {
        camera.stop()
    }

    // MARK: Состояние

    public var pageCount: Int { camera.pages.count }

    public var hasPages: Bool { !camera.pages.isEmpty }

    public var isAutomatic: Bool { camera.isAutomatic }

    public var isFlashOn: Bool { camera.flash == .on }

    public var isDenied: Bool { camera.access == .denied }

    public var quad: DocumentQuad? { camera.quad }

    public var frameAspectRatio: CGFloat { camera.frameAspectRatio }

    // MARK: Подписи

    /// Только количество: рядом стоит стопка с тем же числом, и слово
    /// «снято» в неё уже вписано — на подпись остаётся полоска в семь десятков
    /// точек, где длинная строка ломается пополам.
    public var pagesText: String {
        CountFormatter.string(pageCount, .page)
    }

    /// Что делать прямо сейчас. Подсказка говорит про кадр, а не про кнопки:
    /// на съёмке человек смотрит в видоискатель, а не на интерфейс.
    public var hintText: String {
        if camera.isAtLimit {
            let limit = CountFormatter.string(pageLimit, .page)
            return L10n.Camera.limitReached(limit)
        }
        if !camera.isAutomatic {
            return L10n.Camera.manualHint
        }
        guard camera.quad != nil else {
            return L10n.Camera.aimHint
        }
        if camera.isFocusing {
            return L10n.Camera.focusing
        }
        return L10n.Camera.boundsFound
    }

    public var flashLabel: String {
        isFlashOn
            ? L10n.Camera.flashOn
            : L10n.Camera.flashAuto
    }

    public var automaticLabel: String {
        isAutomatic
            ? L10n.Camera.autoCapture
            : L10n.Camera.manual
    }

    public var doneTitle: String {
        hasPages
            ? L10n.Camera.doneCount(pageCount)
            : L10n.Camera.done
    }

    // MARK: Управление

    public func toggleFlash() {
        camera.flash = isFlashOn ? .auto : .on
    }

    public func toggleAutomatic() {
        camera.isAutomatic.toggle()
    }

    public func shoot() async {
        guard !camera.isAtLimit else {
            let limit = CountFormatter.string(pageLimit, .page)
            say(L10n.Camera.limitSpoken(limit))
            return
        }

        let before = pageCount
        await camera.shoot()

        guard pageCount > before else {
            reportFailure()
            return
        }
        reportShot()
    }

    // MARK: Навигация

    /// Отказ от съёмки выбрасывает снятое: возвращаться к этим страницам
    /// уже некуда — экран закрывается вместе со своим состоянием.
    public func cancel() {
        analytics.didCancelCamera(count: pageCount)
        camera.stop()
        camera.discardPages()
        router.dismiss()
    }

    /// Дальше страницы идут общим путём флоу, поэтому шаг с границами
    /// встаёт в стек под камерой, а не внутри неё.
    public func finish() {
        guard hasPages else { return }

        let pages = camera.pages
        analytics.didCapturePages(count: pages.count, isAutomatic: isAutomatic)
        camera.stop()

        let parent = router.parent ?? router
        router.dismiss()
        parent.push(ScanRoute.pages(items: pages))
    }

    // MARK: Сообщения

    private func reportShot() {
        say(L10n.Camera.pageCaptured(pageCount))
    }

    private func reportFailure() {
        guard let failure = camera.failure else { return }
        camera.clearFailure()
        say(failure)
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
