import AVFoundation
import CoreMedia
import Foundation
import QuartzCore
import SlimlyCore
import Vision

/// Снятый кадр — ровно то, что нужно унести с очереди камеры на главный поток.
struct CapturedPhoto: Sendable {
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int
}

enum DocumentCameraError: LocalizedError {
    case unavailable
    case captureFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: "Камера недоступна на этом устройстве"
        case let .captureFailed(reason): "Снимок не получился: \(reason)"
        }
    }
}

/// Аппаратная часть камеры на собственной очереди.
///
/// Отдельно от наблюдаемого состояния, потому что живёт по другим правилам:
/// `AVCaptureSession` не `Sendable`, а `startRunning()` держит поток вызова
/// столько, сколько ему нужно, — на главном это заметная пауза при открытии
/// экрана. Класс `@unchecked Sendable` осознанно: всю работу с сессией
/// он выполняет на своей последовательной очереди.
final class CaptureBox: @unchecked Sendable {
    /// Кадр показывает системный слой превью, поэтому сессию он берёт отсюда.
    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.slimly.scan.camera")
    private let frameQueue = DispatchQueue(label: "com.slimly.scan.camera.frames")

    /// Делегаты снимков живут ровно до своего кадра: `AVCapturePhotoOutput`
    /// их не удерживает, и без этого списка объект умер бы раньше ответа.
    private var pendingShots: [Int64: PhotoCaptureDelegate] = [:]
    private var analyzer: FrameAnalyzer?
    private var isConfigured = false

    /// Портретный кадр: буферы поворачивает сама система, поэтому и Vision,
    /// и превью работают в одной системе координат — той, что видит человек.
    private static let portraitAngle: CGFloat = 90

    // MARK: Настройка

    /// - Returns: `false`, если камеры нет или система не дала её собрать.
    func configure(onFrame: @escaping @Sendable (DocumentQuad?, CGSize) -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                continuation.resume(returning: setUp(onFrame: onFrame))
            }
        }
    }

    private func setUp(onFrame: @escaping @Sendable (DocumentQuad?, CGSize) -> Void) -> Bool {
        guard !isConfigured else { return true }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            return false
        }

        session.beginConfiguration()
        // `.photo` — единственный пресет, который отдаёт полное разрешение
        // матрицы: страница мелким шрифтом на 1080p уже нечитаема.
        session.sessionPreset = .photo

        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)
        session.addOutput(photoOutput)

        // Полное разрешение матрицы: страница мелким шрифтом вычитывается
        // ровно за счёт этих пикселей, а лишние снимет уже сборка документа.
        if
            let largest = device.activeFormat.supportedMaxPhotoDimensions
                .max(by: { $0.width * $0.height < $1.width * $1.height })
        {
            photoOutput.maxPhotoDimensions = largest
        }

        // Кадр собирается дольше, зато со склейкой нескольких экспозиций
        // и оптической стабилизацией. Документ снимают с рук и в комнате,
        // а не на улице: «быстрый» кадр смазывается ровно на буквах, и
        // никакая последующая обработка этого уже не вернёт.
        photoOutput.maxPhotoQualityPrioritization = .quality

        let analyzer = FrameAnalyzer(onFrame: onFrame)
        self.analyzer = analyzer
        videoOutput.setSampleBufferDelegate(analyzer, queue: frameQueue)
        // Поиск границ идёт медленнее съёмки: копить очередь кадров незачем,
        // рамка всё равно рисуется по последнему.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        for output in [photoOutput, videoOutput] as [AVCaptureOutput] {
            guard let connection = output.connection(with: .video) else { continue }
            if connection.isVideoRotationAngleSupported(Self.portraitAngle) {
                connection.videoRotationAngle = Self.portraitAngle
            }
        }

        isConfigured = true
        return true
    }

    // MARK: Работа

    func start() {
        queue.async { [self] in
            guard isConfigured, !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stop() {
        queue.async { [self] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    // MARK: Снимок

    func capture(flash: AVCaptureDevice.FlashMode) async throws -> CapturedPhoto {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                guard isConfigured else {
                    continuation.resume(throwing: DocumentCameraError.unavailable)
                    return
                }

                // Формат задаём явно: по умолчанию камера пишет HEIC, а имя
                // страницы и её расширение выбираются здесь же — расхождение
                // всплыло бы только в «Файлах».
                //
                // Качество на максимуме, потому что этот JPEG — не результат,
                // а исходник: дальше страницу ждут выпрямление, чистка фона
                // и порог, и артефакты сжатия каждый из них только подчеркнёт.
                let format: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.jpeg,
                    AVVideoCompressionPropertiesKey: [AVVideoQualityKey: 1.0],
                ]
                let settings = AVCapturePhotoSettings(format: format)
                settings.photoQualityPrioritization = .quality
                settings.flashMode = photoOutput.supportedFlashModes.contains(flash) ? flash : .off

                let uniqueID = settings.uniqueID
                let delegate = PhotoCaptureDelegate { [weak self] result in
                    continuation.resume(with: result)
                    self?.releaseShot(uniqueID)
                }
                pendingShots[uniqueID] = delegate
                photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    private func releaseShot(_ uniqueID: Int64) {
        queue.async { [self] in
            pendingShots[uniqueID] = nil
        }
    }
}

// MARK: - Ответ на снимок

/// Один снимок — один делегат: `AVCapturePhotoOutput` отвечает несколькими
/// вызовами, и общий делегат пришлось бы разбирать по номерам настроек.
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let completion: @Sendable (Result<CapturedPhoto, Error>) -> Void

    init(completion: @escaping @Sendable (Result<CapturedPhoto, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(DocumentCameraError.captureFailed(error.localizedDescription)))
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(DocumentCameraError.captureFailed("кадр пустой")))
            return
        }

        let size = photo.resolvedSettings.photoDimensions
        completion(
            .success(
                CapturedPhoto(
                    data: data,
                    pixelWidth: Int(size.width),
                    pixelHeight: Int(size.height)
                )
            )
        )
    }
}

// MARK: - Поиск границ листа

/// Ищет лист в живом кадре.
///
/// Тот же `VNDetectDocumentSegmentationRequest`, что и при сборке страницы:
/// рамка на экране должна обещать ровно то, что потом вырежется, — иначе
/// человек выравнивает кадр по одной границе, а получает другую.
private final class FrameAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// Кадров в секунду для поиска границ. Камера отдаёт тридцать, но
    /// сегментация столько не успевает, а рамка от частоты выше шести
    /// не становится точнее — только дрожит.
    private static let interval: CFTimeInterval = 1.0 / 6

    private let onFrame: @Sendable (DocumentQuad?, CGSize) -> Void
    /// Меняется только на очереди кадров — она последовательная.
    private var lastAnalysis: CFTimeInterval = 0

    init(onFrame: @escaping @Sendable (DocumentQuad?, CGSize) -> Void) {
        self.onFrame = onFrame
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard now - lastAnalysis >= Self.interval else { return }
        lastAnalysis = now

        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let frame = CGSize(
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
        )

        let request = VNDetectDocumentSegmentationRequest()
        try? VNImageRequestHandler(cvPixelBuffer: buffer, options: [:]).perform([request])

        guard let quad = request.results?.first, quad.confidence > 0.5 else {
            onFrame(nil, frame)
            return
        }
        onFrame(DocumentQuad(quad), frame)
    }
}
