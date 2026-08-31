import AVFoundation
import Observation
import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

/// Просмотр готовой звуковой дорожки: огибающая, ход воспроизведения
/// и одна кнопка.
///
/// У дорожки нет кадра, а системный `VideoPlayer` показал бы на её месте
/// чёрный прямоугольник — то есть «ничего не вышло». Поэтому у звука свой
/// экран: полосы говорят, что в файле есть запись, а кнопка даёт её
/// проверить, не выходя в «Файлы».
public struct MediaAudioPlayer: View {
    /// Полос столько, чтобы рельеф читался и на узком экране: больше —
    /// и они сливаются в сплошную заливку.
    private static let barCount = 56

    private let url: URL
    @State private var playback = AudioTrackPlayback()

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        VStack(spacing: 14) {
            waveform
            controls
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        // Прижимаемся к низу окна просмотра: сверху оно держит свою подпись,
        // и полосы не должны под неё подлезать.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .task(id: url) { await playback.open(url, bars: Self.barCount) }
        // Звук не должен продолжаться за спиной у пользователя, ушедшего
        // с экрана: модалка шаринга и возврат назад гасят дорожку.
        .onDisappear { playback.stop() }
    }

    @ViewBuilder
    private var waveform: some View {
        if playback.bars.isEmpty {
            // Пока полосы считаются — спиннер, а не ровная линия: ровная
            // линия означала бы тишину в файле.
            SlimlySpinner(size: 24, lineWidth: 2.5)
                .frame(maxWidth: .infinity, minHeight: 62)
        } else {
            GeometryReader { proxy in
                WaveformBars(bars: playback.bars, progress: playback.progress)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { playback.scrub(to: $0.location.x / proxy.size.width) }
                            .onEnded { playback.commitScrub(at: $0.location.x / proxy.size.width) }
                    )
            }
            .frame(height: 62)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { playback.toggle() } label: {
                SlimlyIcon(playback.isPlaying ? .pause : .play, width: 18)
                    .foregroundStyle(SlimlyColor.accent200)
                    .frame(width: 40, height: 40)
                    .background(SlimlyColor.accentTint(12), in: Circle())
                    .overlay(Circle().strokeBorder(SlimlyColor.accent, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playback.isPlaying ? "Пауза" : "Слушать")

            Text(playback.elapsedText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(SlimlyColor.accent300)

            Spacer(minLength: 0)

            Text(playback.durationText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(SlimlyColor.neutral600)
        }
    }
}

/// Полосы огибающей: пройденное — акцентом, остаток — нейтралью.
private struct WaveformBars: View {
    let bars: [Double]
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let gap: CGFloat = 3
            let width = max(1, (size.width - gap * CGFloat(bars.count - 1)) / CGFloat(bars.count))
            let played = Double(bars.count) * progress

            for (index, bar) in bars.enumerated() {
                // Совсем тихие места всё равно рисуем точкой: разрыв в ряду
                // читался бы как дыра в файле, а не как пауза в записи.
                let height = max(width, bar * size.height)
                let rect = CGRect(
                    x: CGFloat(index) * (width + gap),
                    y: (size.height - height) / 2,
                    width: width,
                    height: height
                )

                context.fill(
                    Path(roundedRect: rect, cornerRadius: width / 2),
                    with: .color(Double(index) < played ? SlimlyColor.accent : SlimlyColor.neutral700)
                )
            }
        }
    }
}

/// Воспроизведение одной дорожки: ход, длительность и огибающая.
///
/// Отдельно от вью, потому что состояние переживает перерисовки: у `AVPlayer`
/// нельзя каждый кадр отбирать позицию, а полосы считаются один раз на файл.
@MainActor
@Observable
private final class AudioTrackPlayback {
    private(set) var bars: [Double] = []
    private(set) var isPlaying = false
    /// Доля пройденного, 0…1. Во время перетаскивания её задаёт палец,
    /// а не плеер: иначе полосы дёргались бы между пальцем и отставшим
    /// от него звуком.
    private(set) var progress: Double = 0

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var duration: Duration = .zero
    @ObservationIgnored private var ticker: Any?
    @ObservationIgnored private var endWatcher: (any NSObjectProtocol)?
    @ObservationIgnored private var isScrubbing = false

    func open(_ url: URL, bars barCount: Int) async {
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        watchProgress()
        watchEnd()

        let asset = AVURLAsset(url: url)
        duration = .seconds((try? await asset.load(.duration).seconds) ?? 0)
        bars = await AudioWaveform.peaks(at: url, count: barCount)
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func stop() {
        pause()
        ticker.map(player.removeTimeObserver)
        ticker = nil
        endWatcher.map(NotificationCenter.default.removeObserver)
        endWatcher = nil
    }

    /// Перетаскивание: картинку двигаем сразу, звук — тоже, но с грубым
    /// допуском. Точная перемотка на каждое движение пальца захлёбывается.
    func scrub(to fraction: Double) {
        isScrubbing = true
        progress = fraction.clamped
        player.seek(to: time(at: progress))
    }

    func commitScrub(at fraction: Double) {
        progress = fraction.clamped
        player.seek(to: time(at: progress), toleranceBefore: .zero, toleranceAfter: .zero)
        isScrubbing = false
    }

    var elapsedText: String { DurationFormatter.string(.seconds(duration.seconds * progress)) }

    var durationText: String { DurationFormatter.string(duration) }

    private func play() {
        // Дорожку слушают ради проверки результата — беззвучный режим
        // здесь означал бы «файл не получился».
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        // С конца начинаем сначала: иначе кнопка «слушать» на доигравшей
        // дорожке не делала бы ничего.
        if progress >= 0.999 { player.seek(to: .zero) }
        player.play()
        isPlaying = true
    }

    private func pause() {
        player.pause()
        isPlaying = false
        // Возвращаем звук тому, у кого мы его забрали: чужой плейлист
        // после проверки дорожки должен продолжиться сам.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func watchProgress() {
        guard ticker == nil else { return }

        ticker = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            // Наблюдатель заведомо приходит в главную очередь — компилятору
            // об этом сказать больше нечем.
            MainActor.assumeIsolated {
                guard let self, !self.isScrubbing, self.duration.seconds > 0 else { return }
                self.progress = (time.seconds / self.duration.seconds).clamped
            }
        }
    }

    /// Доигравшая дорожка должна выглядеть доигравшей: без этого кнопка
    /// осталась бы в состоянии «играет», а полосы — недокрашенными.
    private func watchEnd() {
        guard endWatcher == nil else { return }

        endWatcher = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isPlaying = false
                self.progress = 1
            }
        }
    }

    private func time(at fraction: Double) -> CMTime {
        CMTime(seconds: duration.seconds * fraction, preferredTimescale: 600)
    }
}

private extension Double {
    var clamped: Double { min(max(self, 0), 1) }
}
