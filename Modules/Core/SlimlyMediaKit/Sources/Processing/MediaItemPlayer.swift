import AVFoundation
import Photos
import PhotosUI
import SlimlyCore
import SwiftUI

/// Воспроизведение файла медиатеки: ролик и живое фото оживают прямо
/// в превью выбора, а не превращаются в застывший кадр.
///
/// Живёт в модуле системной обработки вместе с остальным AVKit и PhotoKit:
/// шагам флоу плеер приезжает вью-фабрикой из composition root.
public struct MediaItemPlayer: View {
    private let item: MediaItem
    private let library: any MediaLibrary

    public init(item: MediaItem, library: any MediaLibrary) {
        self.item = item
        self.library = library
    }

    public var body: some View {
        // Живое фото — тоже фото, поэтому проверяем его первым: у такого
        // ассета есть и кадр, и ролик, и играть нужно именно ролик.
        if item.isLivePhoto {
            LivePhotoPlayback(item: item)
        } else if item.kind == .video {
            VideoPlayback(item: item, library: library)
        }
    }
}

// MARK: Видео

/// Ролик под превью: зациклен и без звука.
///
/// Пока система отдаёт ссылку — а ролик из iCloud она сначала подкачает, —
/// на экране остаётся то, что нарисовано под плеером: кадр миниатюры.
private struct VideoPlayback: View {
    let item: MediaItem
    let library: any MediaLibrary

    @State
    private var url: URL?

    var body: some View {
        ZStack {
            if let url {
                LoopingPlayerView(url: url)
            }
        }
        .task(id: item.id) {
            url = await library.playbackURL(for: item)
        }
    }
}

/// `AVPlayerLayer`, а не системный `VideoPlayer`: в превью контекстного меню
/// панель воспроизведения не нужна и нажатия там всё равно не проходят —
/// нужен только сам кадр.
private struct LoopingPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerHostView {
        let view = PlayerHostView()
        view.play(url)
        return view
    }

    func updateUIView(_ view: PlayerHostView, context: Context) {
        view.play(url)
    }
}

/// Слой плеера — собственный слой вью: так кадр меняет размер вместе с ней,
/// без ручной раскладки в `layoutSubviews`.
private final class PlayerHostView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    // Класс слоя задан выше, поэтому другого типа здесь быть не может.
    // swiftlint:disable:next force_cast
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    /// Держим петлю: без сильной ссылки она умирает вместе с вызовом,
    /// и ролик останавливается на последнем кадре.
    private var looper: AVPlayerLooper?
    /// Плеер продублирован полем, хотя он же лежит в слое: из `deinit`
    /// доступны только хранимые свойства, а `playerLayer` — вычисляемое.
    private var player: AVQueuePlayer?
    private var current: URL?

    func play(_ url: URL) {
        guard current != url else { return }
        current = url

        let player = AVQueuePlayer()
        // Превью открывают жестом, а не нажатием на плеер: неожиданный звук
        // здесь пугает, поэтому смотрим молча.
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        self.player = player

        playerLayer.player = player
        // Кадр заполняет плитку так же, как миниатюра под ним, — иначе при
        // появлении плеера картинка прыгала бы в другие пропорции.
        playerLayer.videoGravity = .resizeAspectFill
        player.play()
    }

    deinit {
        // Вью умирает вместе с закрытием меню, а плеер к этому моменту
        // держит аудиосессию: останавливаем, чтобы не играть в пустоту.
        player?.pause()
    }
}

// MARK: Живое фото

/// Живое фото проигрывается один раз, как в системной галерее: это снимок
/// с движением, а не ролик, и бесконечный повтор читался бы как видео.
private struct LivePhotoPlayback: View {
    let item: MediaItem

    @State
    private var livePhoto: LivePhotoBox?

    var body: some View {
        ZStack {
            if let livePhoto {
                LivePhotoView(livePhoto: livePhoto.value)
            }
        }
        .task(id: item.id) {
            livePhoto = await LivePhotoBox.load(id: item.id)
        }
    }
}

private struct LivePhotoView: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isMuted = true
        view.livePhoto = livePhoto
        view.startPlayback(with: .full)
        return view
    }

    func updateUIView(_ view: PHLivePhotoView, context: Context) {
        guard view.livePhoto !== livePhoto else { return }
        view.livePhoto = livePhoto
        view.startPlayback(with: .full)
    }
}

/// Ссылочная ячейка вокруг `PHLivePhoto`: сам тип не `Sendable`, а забрать
/// его нужно из колбэка PhotoKit в главный актор.
private final class LivePhotoBox: @unchecked Sendable {
    let value: PHLivePhoto

    private init(_ value: PHLivePhoto) {
        self.value = value
    }

    /// Ассет ищем здесь же: живое фото — это пара «кадр + ролик» внутри
    /// PhotoKit, и ссылки на файл, которую можно было бы отдать плееру
    /// через протокол медиатеки, у него нет.
    static func load(id: String) async -> LivePhotoBox? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }

        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            let box = ResumeBox(continuation)
            PHImageManager.default().requestLivePhoto(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { photo, info in
                // Как и с миниатюрами, система вправе позвать обработчик
                // дважды — сначала с черновым вариантом.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
                guard !isDegraded || photo == nil else { return }
                box.resume(with: photo.map(LivePhotoBox.init))
            }
        }
    }
}

/// Однократное возобновление продолжения: PhotoKit зовёт обработчик столько
/// раз, сколько сочтёт нужным, а продолжение принимает ответ один.
private final class ResumeBox: @unchecked Sendable {
    private let continuation: CheckedContinuation<LivePhotoBox?, Never>
    private let lock = NSLock()
    private var isResumed = false

    init(_ continuation: CheckedContinuation<LivePhotoBox?, Never>) {
        self.continuation = continuation
    }

    func resume(with box: LivePhotoBox?) {
        lock.lock()
        defer { lock.unlock() }
        guard !isResumed else { return }
        isResumed = true
        continuation.resume(returning: box)
    }
}
