import Foundation

/// Сборка готовых страниц в один PDF.
protocol DocumentWriting: Sendable {
    /// - Parameter pages: страницы в порядке следования в документе.
    func write(pages: [ScannedPage], to destination: URL, title: String) throws
}

struct PDFDocumentWriter: DocumentWriting {
    func write(pages: [ScannedPage], to destination: URL, title: String) throws {
        try PDFBuilder.write(pages: pages, to: destination, title: title)
    }
}
