import Foundation

/// Обработка файлов и собственная база сделанного.
///
/// База своя, потому что iOS не помнит, что мы делали с файлами: всё,
/// что показано в профиле, приложение записало о себе само.
public protocol MediaProcessingService: Sendable {
    func stats() async -> ProcessingStats

    /// Поток событий обработки. Отмена потока останавливает работу —
    /// как и уход из приложения: фоновой обработки здесь нет.
    func process(_ request: ProcessingRequest) -> AsyncStream<ProcessingEvent>
}
