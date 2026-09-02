import Foundation
import SlimlyCore

/// Снимок страницы → страница скана, готовая лечь в PDF.
protocol ScanPageRendering: Sendable {
    /// - Parameter quad: границы листа, выбранные до обработки. `nil` —
    ///   их никто не задавал, и лист ищем сами.
    func page(at source: URL, mode: ScanMode, quad: DocumentQuad?) throws -> ScannedPage
}

struct ScanPageRenderer: ScanPageRendering {
    func page(at source: URL, mode: ScanMode, quad: DocumentQuad?) throws -> ScannedPage {
        try DocumentScanner.page(at: source, mode: mode, quad: quad)
    }
}
