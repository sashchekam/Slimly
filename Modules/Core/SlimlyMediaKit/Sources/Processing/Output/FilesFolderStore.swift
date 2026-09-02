import Foundation

/// Папка приложения в «Файлах» — туда, чему в медиатеке не место.
protocol FileFolderStoring: Sendable {
    /// Переносит готовый файл в папку и отдаёт его новый адрес.
    func move(_ file: URL, named name: String) throws -> URL
}

struct FilesFolderStore: FileFolderStoring {
    private let folder: URL

    init(folder: URL = URL.documentsDirectory.appending(path: "Slimly", directoryHint: .isDirectory)) {
        self.folder = folder
    }

    /// Имя в «Файлах» не должно затирать прошлый файл с тем же названием.
    func move(_ file: URL, named name: String) throws -> URL {
        let manager = FileManager.default
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)

        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = folder.appending(path: name)
        var suffix = 2

        while manager.fileExists(atPath: candidate.path) {
            candidate = folder.appending(path: "\(base) \(suffix).\(ext)")
            suffix += 1
        }

        try manager.moveItem(at: file, to: candidate)
        // Рабочая папка вокруг файла больше ни за чем не нужна.
        try? manager.removeItem(at: file.deletingLastPathComponent())
        return candidate
    }
}
