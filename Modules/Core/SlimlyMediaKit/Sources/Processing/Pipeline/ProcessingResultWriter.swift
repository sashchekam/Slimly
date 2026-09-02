import Foundation
import SlimlyCore

/// Запись результата в рабочую папку.
protocol ProcessingResultWriting: Sendable {
    /// - Parameter body: сама запись файла по переданному адресу.
    func write(
        named name: String,
        for item: MediaItem,
        destination: OutputDestination,
        body: (URL) async throws -> Void
    ) async throws -> ProcessingResult
}

/// Недописанный файл после ошибки или отмены не должен пережить попытку:
/// иначе кэш копит куски, которые ни показать, ни сохранить.
struct ProcessingResultWriter: ProcessingResultWriting {
    private let workFiles: any WorkFileProviding

    init(workFiles: any WorkFileProviding = WorkDirectory()) {
        self.workFiles = workFiles
    }

    func write(
        named name: String,
        for item: MediaItem,
        destination: OutputDestination,
        body: (URL) async throws -> Void
    ) async throws -> ProcessingResult {
        let file = try workFiles.makeFile(named: name)

        do {
            try await body(file)

            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0

            return ProcessingResult(
                item: item,
                outputByteCount: Int64(size),
                outputName: name,
                outputURL: file,
                destination: destination
            )
        } catch {
            try? FileManager.default.removeItem(at: file)
            throw error
        }
    }
}
