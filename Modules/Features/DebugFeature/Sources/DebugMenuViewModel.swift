import DebugFeatureInterface
import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation
import UIKit

@MainActor
@Observable
public final class DebugMenuViewModel {
    /// Группа взаимоисключающих подмен: одна крутилка поведения.
    public struct Knob: Identifiable, Sendable {
        public enum ID: String, Sendable {
            case failure
            case onboarding
        }

        public let id: ID
        public let title: String
        public let hint: String
        public let options: [Option]
    }

    public struct Option: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let isSelected: Bool
    }

    /// Раздел меню — отдельный экран, а не переключатель в списке.
    public enum Section: String, CaseIterable, Identifiable, Sendable {
        case remoteConfig
        case analytics

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .remoteConfig: "Remote Config"
            case .analytics: L10n.Menu.analytics
            }
        }
    }

    /// Разовое действие: сработало — и всё, состояния у него нет.
    public enum Action: String, CaseIterable, Identifiable, Sendable {
        case copyDiagnostics
        case resetStats
        case resetKnobs

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .copyDiagnostics: L10n.Action.copyDiagnostics
            case .resetStats: L10n.Action.resetStats
            case .resetKnobs: L10n.Action.resetKnobs
            }
        }

        public var value: String {
            switch self {
            case .copyDiagnostics: L10n.Action.copyDiagnosticsHint
            case .resetStats: L10n.Action.resetStatsHint
            case .resetKnobs: L10n.Action.resetKnobsHint
            }
        }
    }

    /// Варианты отметки о туре: у крутилки те же чипы, что и у остальных,
    /// поэтому булев флаг разложен в пару значений.
    private enum TourMark: String {
        case seen
        case unseen

        var title: String {
            switch self {
            case .seen: L10n.Knob.seen
            case .unseen: L10n.Knob.unseen
            }
        }
    }

    public private(set) var toast: String?

    private let settings: DebugSettings
    private let statsStore: ProcessingStatsStore
    private let onboardingState: any OnboardingState
    private let analyticsLog: AnalyticsLog
    private let environment: AppEnvironment
    private let router: Router

    /// Копия отметки о туре: хранилище об изменениях не сообщает, а чип
    /// выбранного варианта должен перекрашиваться сразу.
    private var isTourSeen: Bool

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    public init(
        settings: DebugSettings,
        statsStore: ProcessingStatsStore,
        onboardingState: any OnboardingState,
        analyticsLog: AnalyticsLog,
        environment: AppEnvironment,
        router: Router
    ) {
        self.settings = settings
        self.statsStore = statsStore
        self.onboardingState = onboardingState
        self.analyticsLog = analyticsLog
        self.environment = environment
        self.router = router
        isTourSeen = onboardingState.hasSeenTour
    }

    /// Шапка меню: с неё начинается любое обращение в поддержку.
    public var summary: String {
        environment.summary
    }

    public var knobs: [Knob] {
        [failureKnob, onboardingKnob]
    }

    public var sections: [Section] {
        Section.allCases
    }

    public var actions: [Action] {
        Action.allCases
    }

    /// Подпись раздела считается на месте, а не лежит в самом разделе: она
    /// говорит о текущем состоянии, и вернувшись с экрана видно, осталось ли
    /// что-то подменённым.
    public func value(for section: Section) -> String {
        switch section {
        case .remoteConfig:
            let count = settings.remoteConfigOverrides.names.count
            return count == 0
                ? L10n.Config.summary
                : L10n.Config.summaryOverrides(count)
        case .analytics:
            let count = analyticsLog.records.count
            return count == 0
                ? L10n.Analytics.summaryEmpty
                : L10n.Analytics.summaryRecords(count)
        }
    }

    private var failureKnob: Knob {
        Knob(
            id: .failure,
            title: L10n.Knob.failureTitle,
            hint: L10n.Knob.failureNote,
            options: SimulatedFailure.allCases.map { failure in
                Option(
                    id: failure.rawValue,
                    title: failure.title,
                    isSelected: failure == settings.simulatedFailure
                )
            }
        )
    }

    /// Тур — корень первого запуска, а не окно поверх хаба: пересобрать корень
    /// на живом экране значит выкинуть пользователя из текущего флоу, поэтому
    /// меню только переставляет отметку, а увидят её при следующем запуске.
    private var onboardingKnob: Knob {
        Knob(
            id: .onboarding,
            title: L10n.Knob.tourTitle,
            hint: L10n.Knob.tourNote,
            options: [
                Option(id: TourMark.seen.rawValue, title: TourMark.seen.title, isSelected: isTourSeen),
                Option(id: TourMark.unseen.rawValue, title: TourMark.unseen.title, isSelected: !isTourSeen),
            ]
        )
    }

    public func select(_ option: Option, in knob: Knob) {
        switch knob.id {
        case .failure:
            guard let failure = SimulatedFailure(rawValue: option.id) else { return }
            settings.setSimulatedFailure(failure)
        case .onboarding:
            guard let mark = TourMark(rawValue: option.id) else { return }
            isTourSeen = mark == .seen
            onboardingState.setTourSeen(isTourSeen)
            say(
                mark == .seen
                    ? L10n.Knob.tourMarked
                    : L10n.Knob.tourCleared
            )
        }
    }

    public func open(_ section: Section) {
        switch section {
        case .remoteConfig: router.push(DebugRoute.remoteConfig)
        case .analytics: router.push(DebugRoute.analytics)
        }
    }

    public func perform(_ action: Action) {
        switch action {
        case .copyDiagnostics:
            // Буфер обмена SwiftUI не отдаёт — за ним приходится идти в UIKit.
            UIPasteboard.general.string = environment.summary
            say(L10n.Action.copyDiagnosticsDone)
        case .resetStats:
            Task {
                await statsStore.reset()
                say(L10n.Action.resetStatsDone)
            }
        case .resetKnobs:
            settings.reset()
            say(L10n.Action.resetKnobsDone)
        }
    }

    /// Меню приезжает модалкой от тряски и пушем по диплинку — «Готово»
    /// закрывает оба случая.
    public func close() {
        if router.parent == nil {
            router.pop()
        } else {
            router.dismiss()
        }
    }

    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}
