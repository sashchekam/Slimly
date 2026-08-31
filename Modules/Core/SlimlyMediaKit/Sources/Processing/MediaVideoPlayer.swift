import AVKit
import SwiftUI

/// Плеер готового файла.
///
/// Живёт здесь, а не в общих шагах флоу: AVKit — тот же системный медиа-мир,
/// что и остальное содержимое модуля, и остальным про него знать незачем.
/// Экранам плеер приезжает вью-фабрикой из composition root.
public struct MediaVideoPlayer: View {
    private let url: URL
    @State private var player = AVPlayer()

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        VideoPlayer(player: player)
            // Ролик меняется при переключении «оригинал / результат»:
            // подменяем предмет у того же плеера, а не создаём новый —
            // иначе на каждом переключении мигал бы чёрный кадр.
            .task(id: url) {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
                player.play()
            }
            .onDisappear { player.pause() }
    }
}
