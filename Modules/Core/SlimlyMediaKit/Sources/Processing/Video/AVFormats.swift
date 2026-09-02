import AVFoundation
import SlimlyCore

extension VideoContainer {
    var fileType: AVFileType {
        switch self {
        case .mp4: .mp4
        case .mov: .mov
        }
    }
}

extension VideoCodec {
    var avCodec: AVVideoCodecType {
        switch self {
        case .h264: .h264
        case .hevc: .hevc
        }
    }
}

extension AudioFormat {
    var fileType: AVFileType {
        switch self {
        case .aac: .m4a
        case .linearPCM: .wav
        }
    }
}
