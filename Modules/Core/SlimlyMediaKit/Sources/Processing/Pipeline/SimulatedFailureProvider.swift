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

/// Читает подмену из того же хранилища, куда её пишет отладочное меню:
/// обработчик файлов живёт вне главного актора, и дотянуться до самого
/// меню ему нечем.
struct SimulatedFailureProvider: SimulatedFailureProviding {
    private let storage: any KeyValueStorage

    init(storage: any KeyValueStorage = DefaultsStorage()) {
        self.storage = storage
    }

    func reason() -> String? {
        #if DEBUG
        storage.value(for: .simulatedFailure, default: .off).reason
        #else
        nil
        #endif
    }
}
