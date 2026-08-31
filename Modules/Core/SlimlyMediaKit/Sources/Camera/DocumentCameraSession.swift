import AVFoundation
import CoreGraphics
import Foundation
import Observation
import SlimlyCore

/// Камера скана: живой кадр, границы листа и снятые страницы.
///
/// Состояние экрана целиком, поэтому `@MainActor`: аппаратная часть живёт
/// на своей очереди в ``CaptureBox``, а сюда попадает только то, что рисуется.
/// Страницы держит она же — предел набора относится к съёмке, а не к экрану,
/// и разъезжаться этим двум счётчикам незачем.
@MainActor
@Observable
public final class DocumentCameraSession {
    public enum Access: Sendable, Hashable {
        case notDetermined
        case denied
        case authorized
    }

    /// Вспышка. Выключенного положения нет намеренно: «Авто» на свету
    /// её и так не зажигает, а третий пункт в чипе пришлось бы объяснять.
    public enum Flash: Sendable, Hashable {
        case auto
        case on

        var mode: AVCaptureDevice.FlashMode {
            self == .on ? .on : .auto
        }
    }

    public private(set) var access: Access = .notDetermined
    /// Границы листа в текущем кадре или `nil`, если листа не видно.
    public private(set) var quad: DocumentQuad?
    /// Пропорции кадра — по ним рамка ложится поверх превью.
    public private(set) var frameAspectRatio: CGFloat = 3 / 4
    /// Снятые страницы в порядке съёмки.
    public private(set) var pages: [MediaItem] = []
    /// Затвор занят: пока кадр пишется, второй не снимаем.
    public private(set) var isBusy = false
    /// Причина последнего отказа. Читающий её обнуляет — она одноразовая.
    public private(set) var failure: String?

    /// Автосъёмка: кадр уходит сам, как только границы перестают шевелиться.
    public var isAutomatic = true
    public var flash: Flash = .auto

    /// Съёмка закончилась сама. Экрану нужно сказать об этом человеку —
    /// в отличие от нажатия затвора, он этого кадра не заказывал.
    @ObservationIgnored
    public var onAutomaticShot: (@MainActor @Sendable () -> Void)?

    @ObservationIgnored
    private let box = CaptureBox()
    @ObservationIgnored
    private let pageLimit: Int
    @ObservationIgnored
    private var isConfigured = false
    @ObservationIgnored
    private var steadyFrames = 0

    /// Насколько углам позволено дрожать между кадрами, чтобы лист считался
    /// неподвижным. Полпроцента кадра — это дрожание руки, а не сдвиг листа.
    private static let steadyTolerance: CGFloat = 0.005
    /// Сколько спокойных кадров ждём до автоспуска. При шести кадрах
    /// в секунду это примерно секунда — за неё успевают убрать палец.
    private static let steadyFrameCount = 6

    public init(pageLimit: Int) {
        self.pageLimit = pageLimit
    }

    public var isAtLimit: Bool { pages.count >= pageLimit }

    // MARK: Жизненный цикл

    /// Спросить доступ, собрать сессию и пустить кадр.
    ///
    /// Всё за один вызов, потому что порядок здесь жёсткий: без разрешения
    /// сессия соберётся, но покажет чёрный прямоугольник.
    public func start() async {
        access = await Self.requestAccess()
        guard access == .authorized else { return }

        // Страницы прошлой съёмки к этому моменту либо собраны в документ,
        // либо от них отказались: держать их файлы дальше незачем.
        if pages.isEmpty {
            try? FileManager.default.removeItem(at: Self.directory)
        }

        if !isConfigured {
            isConfigured = await box.configure { [weak self] quad, frame in
                Task { @MainActor [weak self] in
                    self?.handle(quad, frame: frame)
                }
            }
        }
        guard isConfigured else {
            failure = DocumentCameraError.unavailable.errorDescription
            return
        }
        box.start()
    }

    public func stop() {
        box.stop()
        quad = nil
        steadyFrames = 0
    }

    /// Сессия для системного слоя превью. Больше её наружу не отдаём:
    /// всё, что можно с ней делать, уже названо методами.
    var captureSession: AVCaptureSession { box.session }

    // MARK: Съёмка

    /// Снять страницу по нажатию затвора.
    public func shoot() async {
        await capture()
    }

    private func capture() async {
        guard access == .authorized, isConfigured, !isBusy, !isAtLimit else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            let photo = try await box.capture(flash: flash.mode)
            pages.append(try store(photo))
        } catch {
            failure = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Страница ложится во временную папку и дальше живёт как обычный
    /// исходник: медиатеке она не принадлежит, поэтому носит с собой файл.
    private func store(_ photo: CapturedPhoto) throws -> MediaItem {
        let directory = Self.directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let file = directory.appending(path: "\(UUID().uuidString).jpg")
        try photo.data.write(to: file, options: .atomic)

        return MediaItem(
            id: file.path,
            kind: .photo,
            fileName: "Страница \(pages.count + 1).jpg",
            byteCount: Int64(photo.data.count),
            pixelWidth: photo.pixelWidth,
            pixelHeight: photo.pixelHeight,
            sourceURL: file
        )
    }

    /// Выбросить снятое. Файлы удаляем сразу: страницы, от которых человек
    /// отказался, не должны копиться во временной папке до перезапуска.
    public func discardPages() {
        for page in pages {
            guard let url = page.sourceURL else { continue }
            try? FileManager.default.removeItem(at: url)
        }
        pages.removeAll()
        steadyFrames = 0
    }

    public func clearFailure() {
        failure = nil
    }

    private static var directory: URL {
        URL.cachesDirectory.appending(path: "Slimly/Scan", directoryHint: .isDirectory)
    }

    // MARK: Кадр

    private func handle(_ found: DocumentQuad?, frame: CGSize) {
        // Присваиваем только изменившееся: кадры идут шесть раз в секунду,
        // и каждая запись в наблюдаемое свойство перерисовывает экран.
        if frame.height > 0 {
            let aspect = frame.width / frame.height
            if abs(aspect - frameAspectRatio) > 0.001 {
                frameAspectRatio = aspect
            }
        }

        let previous = quad
        if quad != found {
            quad = found
        }

        guard isAutomatic, !isBusy, !isAtLimit, let found else {
            steadyFrames = 0
            return
        }
        guard let previous, found.drift(from: previous) < Self.steadyTolerance else {
            // Первый кадр с листом уже считается спокойным: сравнивать его
            // не с чем, а начинать отсчёт с нуля значило бы терять секунду.
            steadyFrames = 1
            return
        }

        steadyFrames += 1
        guard steadyFrames >= Self.steadyFrameCount else { return }
        steadyFrames = 0

        Task { [weak self] in
            guard let self else { return }
            let before = pages.count
            await capture()
            guard pages.count > before else { return }
            onAutomaticShot?()
        }
    }

    // MARK: Доступ

    private static func requestAccess() async -> Access {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }
}
