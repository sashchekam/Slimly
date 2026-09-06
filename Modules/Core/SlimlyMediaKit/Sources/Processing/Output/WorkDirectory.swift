import Foundation

/// Рабочая папка в кэше. Здесь результат живёт до сохранения, и здесь же
/// остаётся после — на экране сравнения «до / после».
protocol WorkFileProviding: Sendable {
    func makeFile(named name: String) throws -> URL
    /// Тот же файл под новым именем. Отдаёт новый адрес: имя файла —
    /// часть пути, и старая ссылка после переименования никуда не ведёт.
    func rename(_ file: URL, to name: String) throws -> URL
    /// Кэш чистим на старте: сохранённое лежит там, где ему положено,
    /// а несохранённое человек сохранять не стал — предлагать ему прошлый
    /// результат новым запуском было бы странно.
    func clear()
}

struct WorkDirectory: WorkFileProviding {
    private let root: URL

    init(root: URL = URL.cachesDirectory.appending(path: "Slimly/Output", directoryHint: .isDirectory)) {
        self.root = root
    }

    /// Готовый файл лежит под своим настоящим именем, а уникальность даёт
    /// папка вокруг него: имя файла видно в системной шторке шаринга,
    /// и «B7F1-…-4C2A.jpg» там выглядело бы поломкой.
    func makeFile(named name: String) throws -> URL {
        let folder = root.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: name)
    }

    /// Переименование — это переезд в новую папку, а не правка имени на месте:
    /// файловая система здесь не различает регистр, и «foto.jpg» → «Foto.jpg»
    /// на месте не прошло бы.
    func rename(_ file: URL, to name: String) throws -> URL {
        let target = try makeFile(named: name)
        try FileManager.default.moveItem(at: file, to: target)
        try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
        return target
    }

    func clear() {
        try? FileManager.default.removeItem(at: root)
    }
}
