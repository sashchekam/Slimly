import Foundation
import SlimlyCore

/// Куда попадает готовый файл.
///
/// Фото и видео уходят в медиатеку — там их ищут. Звуку в медиатеке места
/// нет, поэтому дорожки ложатся в папку приложения, которая видна в «Файлах».
struct OutputStore: Sendable {
    private let library: any MediaLibrary

    init(library: any MediaLibrary) {
        self.library = library
    }

    /// Рабочая папка в кэше: результат нужен ещё и после сохранения —
    /// на экране сравнения «до / после».
    static var workDirectory: URL {
        URL.cachesDirectory.appending(path: "Slimly/Output", directoryHint: .isDirectory)
    }

    /// Папка приложения в «Файлах».
    static var filesDirectory: URL {
        URL.documentsDirectory.appending(path: "Slimly", directoryHint: .isDirectory)
    }

    /// Кэш чистим на старте: файлы прошлых сессий уже сохранены там,
    /// где им положено, и держать их копии незачем.
    static func clearWorkDirectory() {
        try? FileManager.default.removeItem(at: workDirectory)
    }

    /// Готовый файл лежит под своим настоящим именем, а уникальность даёт
    /// папка вокруг него: имя файла видно в системной шторке шаринга,
    /// и «B7F1-…-4C2A.jpg» там выглядело бы поломкой.
    func makeWorkFile(named name: String) throws -> URL {
        let folder = Self.workDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: name)
    }

    /// Разложить готовый файл по месту и сказать, куда он лёг.
    func store(
        _ file: URL,
        kind: MediaKind,
        name: String,
        destination: OutputDestination
    ) async throws -> URL {
        switch destination {
        case .photoLibrary:
            _ = try await library.saveToLibrary(file, kind: kind)
            return file
        case .files:
            return try move(file, to: name)
        }
    }

    /// Имя в «Файлах» не должно затирать прошлую дорожку с тем же названием.
    private func move(_ file: URL, to name: String) throws -> URL {
        let manager = FileManager.default
        try manager.createDirectory(at: Self.filesDirectory, withIntermediateDirectories: true)

        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = Self.filesDirectory.appending(path: name)
        var suffix = 2

        while manager.fileExists(atPath: candidate.path) {
            candidate = Self.filesDirectory.appending(path: "\(base) \(suffix).\(ext)")
            suffix += 1
        }

        try manager.moveItem(at: file, to: candidate)
        // Рабочая папка вокруг файла больше ни за чем не нужна.
        try? manager.removeItem(at: file.deletingLastPathComponent())
        return candidate
    }
}
