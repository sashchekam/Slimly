import Foundation
import SlimlyCore

/// Подмена отказа из отладочного меню.
///
/// Дождаться настоящего отказа от системы почти нельзя — место кончается
/// редко, — а список отказов на экране итога проверять надо.
protocol SimulatedFailureProviding: Sendable {
    /// Причина, которой подменяется обработка. `nil` — работаем по-настоящему.
    func reason() -> String?
}

struct SimulatedFailureProvider: SimulatedFailureProviding {
    func reason() -> String? {
        #if DEBUG
        SimulatedFailure.stored().reason
        #else
        nil
        #endif
    }
}
