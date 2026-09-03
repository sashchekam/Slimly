import Foundation
import SlimlyCore

/// Куда попадает сохранённый файл.
///
/// Фото и видео уходят в медиатеку — там их ищут. Звуку и документам
/// в медиатеке места нет, поэтому они ложатся в папку приложения, которая
/// видна в «Файлах». Само раскладывание происходит только по кнопке
/// на экране итога: до неё результат не покидает рабочую папку.
protocol OutputStoring: Sendable {
    /// Разложить готовый файл по месту и сказать, куда он лёг.
    ///
    /// - Parameter source: элемент, из которого файл получен: в медиатеке
    ///   результат наследует его дату и геометку.
    func store(
        _ file: URL,
        kind: MediaKind,
        name: String,
        source: MediaItem?,
        destination: OutputDestination
    ) async throws -> URL
}

struct OutputStore: OutputStoring {
    private let library: any MediaLibrary
    private let files: any FileFolderStoring

    init(library: any MediaLibrary, files: any FileFolderStoring = FilesFolderStore()) {
        self.library = library
        self.files = files
    }

    func store(
        _ file: URL,
        kind: MediaKind,
        name: String,
        source: MediaItem?,
        destination: OutputDestination
    ) async throws -> URL {
        switch destination {
        case .photoLibrary:
            _ = try await library.saveToLibrary(file, kind: kind, inheritingFrom: source)
            return file
        case .files:
            return try files.move(file, named: name)
        }
    }
}
