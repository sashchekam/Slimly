import Foundation
import Observation
import CompressFeatureInterface
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class SetupViewModel {
    public let items: [MediaItem]
    public var options: CompressionOptions

    private let router: Router

    public init(items: [MediaItem], options: CompressionOptions, router: Router) {
        self.items = items
        self.options = options
        self.router = router
    }

    public var summary: String {
        "\(CountFormatter.files(items.count)) · \(originalText)"
    }

    public var originalText: String {
        FileSizeFormatter.string(bytes: items.totalByteCount)
    }

    public var estimatedText: String {
        FileSizeFormatter.string(bytes: CompressionEstimate.byteCount(for: items, preset: options.preset))
    }

    /// Оценка для карточки пресета — показывается у каждого варианта,
    /// чтобы выбор был виден в килобайтах, а не только в словах.
    public func estimate(for preset: CompressionPreset) -> String {
        "≈ \(FileSizeFormatter.string(bytes: CompressionEstimate.byteCount(for: items, preset: preset)))"
    }

    public var remainingFraction: Double { options.preset.ratio }

    public var ctaTitle: String {
        "Сжать · \(originalText) → ≈ \(estimatedText)"
    }

    public func select(_ preset: CompressionPreset) {
        options.preset = preset
    }

    public func goBack() {
        router.pop()
    }

    public func start() {
        router.push(CompressRoute.run(items: items, options: options))
    }
}
