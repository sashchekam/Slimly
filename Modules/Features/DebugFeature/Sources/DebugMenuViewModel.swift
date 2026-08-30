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

    /// Разовое действие: сработало — и всё, состояния у него нет.
    public enum Action: String, CaseIterable, Identifiable, Sendable {
        case copyDiagnostics
        case resetStats
        case resetKnobs

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .copyDiagnostics: "Скопировать диагностику"
            case .resetStats: "Сбросить статистику"
            case .resetKnobs: "Выключить все подмены"
            }
        }

        public var value: String {
            switch self {
            case .copyDiagnostics: "версия, устройство, ID"
            case .resetStats: "профиль обнулится"
            case .resetKnobs: "вернуть как из App Store"
            }
        }
    }

    public private(set) var toast: String?

    private let settings: DebugSettings
    private let statsStore: ProcessingStatsStore
    private let environment: AppEnvironment
    private let router: Router

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    public init(
        settings: DebugSettings,
        statsStore: ProcessingStatsStore,
        environment: AppEnvironment,
        router: Router
    ) {
        self.settings = settings
        self.statsStore = statsStore
        self.environment = environment
        self.router = router
    }

    /// Шапка меню: с неё начинается любое обращение в поддержку.
    public var summary: String {
        environment.summary
    }

    public var knobs: [Knob] {
        [failureKnob]
    }

    public var actions: [Action] {
        Action.allCases
    }

    private var failureKnob: Knob {
        Knob(
            id: .failure,
            title: "Сбой в обработке",
            hint: "Каждый файл отваливается с выбранной причиной — так видно список отказов на экране итога",
            options: SimulatedFailure.allCases.map { failure in
                Option(
                    id: failure.rawValue,
                    title: failure.title,
                    isSelected: failure == settings.simulatedFailure
                )
            }
        )
    }

    public func select(_ option: Option, in knob: Knob) {
        switch knob.id {
        case .failure:
            guard let failure = SimulatedFailure(rawValue: option.id) else { return }
            settings.setSimulatedFailure(failure)
        }
    }

    public func perform(_ action: Action) {
        switch action {
        case .copyDiagnostics:
            // Единственное место фичи, которому нужен UIKit: буфер обмена
            // SwiftUI не отдаёт.
            UIPasteboard.general.string = environment.summary
            say("Диагностика скопирована в буфер")
        case .resetStats:
            Task {
                await statsStore.reset()
                say("Статистика профиля обнулена")
            }
        case .resetKnobs:
            settings.reset()
            say("Подмены выключены")
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
