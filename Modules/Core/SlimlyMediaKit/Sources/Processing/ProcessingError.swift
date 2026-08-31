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

    var errorDescription: String? {
        switch self {
        case .unreadableSource:
            "Файл не читается"
        case let .unsupportedFormat(name):
            "Формат \(name) недоступен на этом устройстве"
        case let .encodingFailed(reason):
            "Не удалось записать результат: \(reason)"
        case .noVideoTrack:
            "В файле нет видеодорожки"
        case .noAudioTrack:
            "В видео нет звука"
        case let .unsupportedOperation(name):
            name
        case .pdfAssemblyFailed:
            "Не удалось собрать PDF из страниц"
        }
    }
}
