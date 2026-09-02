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
    private let livePhotos: any LivePhotoLoading

    public init(item: MediaItem, library: any MediaLibrary) {
        self.init(item: item, library: library, livePhotos: PhotoKitLivePhotoLoader())
    }

    init(item: MediaItem, library: any MediaLibrary, livePhotos: any LivePhotoLoading) {
        self.item = item
        self.library = library
        self.livePhotos = livePhotos
    }

    public var body: some View {
        // Живое фото — тоже фото, поэтому проверяем его первым: у такого
        // ассета есть и кадр, и ролик, и играть нужно именно ролик.
        if item.isLivePhoto {
            LivePhotoPlayback(item: item, livePhotos: livePhotos)
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
    let livePhotos: any LivePhotoLoading

    @State
    private var livePhoto: LivePhotoBox?

    var body: some View {
        ZStack {
            if let livePhoto {
                LivePhotoView(livePhoto: livePhoto.value)
            }
        }
        .task(id: item.id) {
            livePhoto = await livePhotos.livePhoto(id: item.id)
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
