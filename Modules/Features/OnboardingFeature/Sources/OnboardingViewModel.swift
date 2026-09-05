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
    private let analytics: OnboardingAnalytics
    private let router: Router

    public init(
        pages: [OnboardingPage] = OnboardingPage.tour,
        state: any OnboardingState,
        home: any Route,
        analytics: OnboardingAnalytics,
        router: Router
    ) {
        self.pages = pages
        self.state = state
        self.home = home
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
    }
}
