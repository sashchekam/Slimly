import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class OnboardingViewModel {
    public let pages: [OnboardingPage]

    public private(set) var pageIndex = 0

    private let state: any OnboardingState
    /// Куда уходит тур на последнем шаге. Приходит готовым маршрутом:
    /// какая фича стоит за главным экраном, туру знать незачем.
    private let home: any Route
    /// Пейволл после тура. Замыканием, а не значением: показывать его или
    /// нет, решает удалённый конфиг, а свежие значения приезжают уже после
    /// старта — на момент сборки резолвера ответа ещё нет.
    private let paywall: () -> (any Route)?
    private let analytics: OnboardingAnalytics
    private let router: Router

    public init(
        pages: [OnboardingPage] = OnboardingPage.tour,
        state: any OnboardingState,
        home: any Route,
        paywall: @escaping () -> (any Route)? = { nil },
        analytics: OnboardingAnalytics,
        router: Router
    ) {
        self.pages = pages
        self.state = state
        self.home = home
        self.paywall = paywall
        self.analytics = analytics
        self.router = router
    }

    public var currentPage: OnboardingPage {
        pages[pageIndex]
    }

    public var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    /// На последнем шаге кнопка перестаёт вести дальше и становится входом
    /// в приложение — иначе «Далее» упиралось бы в пустоту.
    public var nextTitle: String {
        isLastPage
            ? L10n.Tour.start
            : L10n.Tour.next
    }

    public func next() {
        guard !isLastPage else {
            finish(skipped: false)
            return
        }
        pageIndex += 1
        analytics.didOpenPage(pageIndex)
    }

    /// «Пропустить» и крестик — одно и то же действие: тур засчитан
    /// показанным. Второй раз его никто не ждёт, а если понадобится —
    /// он открывается ссылкой.
    public func skip() {
        finish(skipped: true)
    }

    private func finish(skipped: Bool) {
        analytics.didFinish(page: pageIndex, skipped: skipped)
        state.markTourSeen()
        router.restart(with: home)
        showPaywall()
    }

    /// Пейволл ждёт конца смены корня: главный экран приезжает с переходом,
    /// и модалка, выехавшая поверх ещё едущего экрана, читается как сбой.
    /// Пропуск тура тоже ведёт сюда — отказ смотреть картинки не означает
    /// отказ от тарифа.
    private func showPaywall() {
        guard let paywall = paywall() else { return }

        Task {
            try? await Task.sleep(for: .seconds(0.55))
            router.topmost.cover(paywall)
        }
    }
}
