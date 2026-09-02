import AVFoundation
import Foundation

/// Огибающая громкости готовой дорожки.
///
/// Просмотр звука без картинки — это полосы: по ним видно, где речь,
/// где пауза, и что файл вообще не пустой. Считаем по самому результату,
/// а не по исходному видео: показывать нужно то, что получилось.
protocol AudioWaveformReading: Sendable {
    /// Пики по `count` равным отрезкам, нормированные к самому громкому.
    ///
    /// Пустой массив значит «прочитать не удалось» — экран покажет это
    /// заглушкой, а не ровной линией: ровная линия читалась бы как тишина,
    /// то есть как испорченный файл.
    func peaks(at url: URL, count: Int) async -> [Double]
}

struct AudioWaveformReader: AudioWaveformReading {
    private let steps: any WaveformSamplingStepEstimating
    private let samples: any WaveformPeakReading
    private let shaper: any WaveformShaping

    init(
        steps: any WaveformSamplingStepEstimating = WaveformSamplingStep(),
        samples: any WaveformPeakReading = WaveformPeakReader(),
        shaper: any WaveformShaping = WaveformShaper()
    ) {
        self.steps = steps
        self.samples = samples
        self.shaper = shaper
    }

    func peaks(at url: URL, count: Int) async -> [Double] {
        let asset = AVURLAsset(url: url)

        guard
            let track = try? await asset.loadTracks(withMediaType: .audio).first,
            let reader = try? AVAssetReader(asset: asset)
        else { return [] }

        // Просим распакованный 16-битный PCM: у AAC отсчётов в файле нет,
        // а по сжатым кадрам громкость не измерить.
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
        )

        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        guard reader.startReading() else { return [] }

        let step = await steps.step(of: track, in: asset, bars: count)
        let fine = samples.peaks(from: output, every: step)
        reader.cancelReading()

        return shaper.shape(fine, to: count)
    }
}
