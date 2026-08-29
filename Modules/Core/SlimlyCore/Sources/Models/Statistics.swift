import Foundation

/// Что о медиатеке отдаёт система.
///
/// Общего веса медиатеки iOS не сообщает, поэтому его здесь нет и быть
/// не может: доступны только количества и свободное место на устройстве.
public struct LibrarySnapshot: Sendable, Hashable {
    public let photoCount: Int
    public let videoCount: Int
    public let freeSpace: Int64

    public init(photoCount: Int, videoCount: Int, freeSpace: Int64) {
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.freeSpace = freeSpace
    }
}

/// Что мы обработали сами — единственные цифры о весе, за которые можем отвечать.
public struct CompressionStats: Sendable, Hashable {
    public let originalByteCount: Int64
    public let compressedByteCount: Int64
    public let photoCount: Int
    public let videoCount: Int
    public let heicConvertedCount: Int
    public let streakDays: Int

    public init(
        originalByteCount: Int64,
        compressedByteCount: Int64,
        photoCount: Int,
        videoCount: Int,
        heicConvertedCount: Int,
        streakDays: Int
    ) {
        self.originalByteCount = originalByteCount
        self.compressedByteCount = compressedByteCount
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.heicConvertedCount = heicConvertedCount
        self.streakDays = streakDays
    }

    public static let empty = CompressionStats(
        originalByteCount: 0,
        compressedByteCount: 0,
        photoCount: 0,
        videoCount: 0,
        heicConvertedCount: 0,
        streakDays: 0
    )

    public var savedByteCount: Int64 { originalByteCount - compressedByteCount }

    public var fileCount: Int { photoCount + videoCount }

    /// Доля оставшегося веса — ширина полосы «стало / было».
    public var remainingFraction: Double {
        guard originalByteCount > 0 else { return 0 }
        return Double(compressedByteCount) / Double(originalByteCount)
    }

    /// Присоединить итог очередной обработки.
    public func adding(_ results: [CompressionResult], options: CompressionOptions) -> CompressionStats {
        CompressionStats(
            originalByteCount: originalByteCount + results.originalByteCount,
            compressedByteCount: compressedByteCount + results.compressedByteCount,
            photoCount: photoCount + results.filter { $0.item.kind == .photo }.count,
            videoCount: videoCount + results.filter { $0.item.kind == .video }.count,
            heicConvertedCount: heicConvertedCount
                + (options.convertsHEICToJPEG ? results.filter(\.item.isHEIC).count : 0),
            streakDays: streakDays
        )
    }
}
