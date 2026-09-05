import Foundation

/// Отказ по одному файлу. Текст попадает в список итога, поэтому написан
/// для пользователя, а не для лога.
enum ProcessingError: LocalizedError {
    case unreadableSource
    case unsupportedFormat(String)
    case encodingFailed(String)
    case noVideoTrack
    case noAudioTrack
    case unsupportedOperation(String)
    case pdfAssemblyFailed
    /// Сохранять нечего: записанного файла нет.
    case outputMissing

    var errorDescription: String? {
        switch self {
        case .unreadableSource:
            L10n.Failure.unreadable
        case let .unsupportedFormat(name):
            L10n.Failure.unsupportedFormat(name)
        case let .encodingFailed(reason):
            L10n.Failure.writeFailed(reason)
        case .noVideoTrack:
            L10n.Failure.noVideoTrack
        case .noAudioTrack:
            L10n.Failure.noAudioTrack
        case let .unsupportedOperation(name):
            name
        case .pdfAssemblyFailed:
            L10n.Failure.pdfAssembly
        case .outputMissing:
            L10n.Failure.resultMissing
        }
    }
}

extension Error {
    /// Причина отказа так, как её увидят на экране итога.
    var processingMessage: String {
        (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}
