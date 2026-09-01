import CoreGraphics
import CoreImage
import Foundation
import Vision
import SlimlyCore

/// Поиск листа тем же запросом Vision, каким его ищет сборка страницы.
///
/// Один запрос на всё приложение — иначе рамка на экране правки обещала бы
/// одни границы, а документ собрался бы по другим.
public struct VisionDocumentBoundsDetector: DocumentBoundsDetector {
    public init() {}

    public func bounds(in imageData: Data) async -> DocumentQuad? {
        // Поиск идёт десятки миллисекунд на кадр — на главном потоке это
        // заметная пауза при листании страниц.
        await Task.detached(priority: .userInitiated) {
            guard let image = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else {
                return nil
            }
            return DocumentQuad.detected(in: image)
        }
        .value
    }
}

extension DocumentQuad {
    /// Ниже этой доли кадра найденный «документ» — не документ, а какой-то
    /// прямоугольник на столе. Тогда честнее считать, что листа не нашли.
    static let minimumDocumentArea = 0.15

    /// Границы листа в кадре или `nil`, если уверенности нет.
    static func detected(in image: CIImage) -> DocumentQuad? {
        let request = VNDetectDocumentSegmentationRequest()
        try? VNImageRequestHandler(ciImage: image, options: [:]).perform([request])

        guard
            let observation = request.results?.first,
            observation.confidence > 0.5,
            observation.boundingBox.width * observation.boundingBox.height > minimumDocumentArea
        else {
            return nil
        }
        return DocumentQuad(observation)
    }

    /// Vision отдаёт доли кадра от левого нижнего угла — переворачиваем ось.
    init(_ observation: VNRectangleObservation) {
        func flipped(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x, y: 1 - point.y)
        }
        self.init(
            topLeft: flipped(observation.topLeft),
            topRight: flipped(observation.topRight),
            bottomRight: flipped(observation.bottomRight),
            bottomLeft: flipped(observation.bottomLeft)
        )
    }
}
