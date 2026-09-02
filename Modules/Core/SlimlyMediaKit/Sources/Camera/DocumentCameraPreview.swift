import AVFoundation
import SwiftUI

/// Живой кадр камеры.
///
/// Системный слой, а не картинка из буфера: превью рисует сама камера,
/// и любое промежуточное звено добавило бы кадру задержку, которая на
/// наведении по границам листа видна сразу.
public struct DocumentCameraPreview: UIViewRepresentable {
    private let camera: DocumentCameraSession

    public init(camera: DocumentCameraSession) {
        self.camera = camera
    }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = camera.captureSession
        // Кадр заполняет экран целиком: поля вокруг превью на съёмке
        // документа только съедают место, которое нужно самой странице.
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) { }

    /// `UIView` поверх слоя превью — так слой всегда точно по размеру вью
    /// и не требует ручной раскладки при поворотах и изменениях кадра.
    public final class PreviewView: UIView {
        override public static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // Класс слоя задан выше, поэтому другого типа здесь быть не может.
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            guard
                let connection = previewLayer.connection,
                connection.isVideoRotationAngleSupported(90)
            else { return }
            connection.videoRotationAngle = 90
        }
    }
}
