import Foundation
import SlimlyCore
import UniformTypeIdentifiers

extension ImageFormat {
    var utType: UTType {
        switch self {
        case .jpeg: .jpeg
        case .heic: .heic
        case .png: .png
        }
    }

    /// Формат исходника по расширению файла — им же и сохраняем при сжатии:
    /// сжатие меняет вес, а не тип файла.
    static func matching(fileExtension: String) -> ImageFormat {
        switch fileExtension.lowercased() {
        case "png": .png
        case "heic", "heif": .heic
        default: .jpeg
        }
    }
}
