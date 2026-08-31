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
///
/// Вес считаем только по сжатию: конвертация может файл и утяжелить
/// (PNG из HEIC), поэтому её складывать в «освобождено» нельзя — она идёт
/// отдельным счётчиком.
public struct ProcessingStats: Sendable, Hashable, Codable {
    public let originalByteCount: Int64
    public let compressedByteCount: Int64
    public let photoCount: Int
    public let videoCount: Int
    public let conversionCount: Int

    public init(
        originalByteCount: Int64,
        compressedByteCount: Int64,
        photoCount: Int,
        videoCount: Int,
        conversionCount: Int
    ) {
        self.originalByteCount = originalByteCount
        self.compressedByteCount = compressedByteCount
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.conversionCount = conversionCount
    }

    public static let empty = ProcessingStats(
        originalByteCount: 0,
        compressedByteCount: 0,
        photoCount: 0,
        videoCount: 0,
        conversionCount: 0
    )

    public var savedByteCount: Int64 { originalByteCount - compressedByteCount }

    public var fileCount: Int { photoCount + videoCount }

    /// Доля оставшегося веса — ширина полосы «стало / было».
    /// Ограничена единицей: полоса не умеет быть длиннее себя, а такой
    /// случай возможен — плотный файл после пережатия иногда тяжелеет.
    public var remainingFraction: Double {
        guard originalByteCount > 0 else { return 0 }
        return min(Double(compressedByteCount) / Double(originalByteCount), 1)
    }

    /// Присоединить итог очередной обработки.
    public func adding(_ outcome: ProcessingOutcome) -> ProcessingStats {
        // Скан в счётчиках не отражается: из пачки снимков получается один
        // PDF, и он не конвертация — считать его наравне с ней значило бы
        // показывать в профиле цифру, которой там нет смысла.
        guard outcome.kind != .scan else { return self }

        guard outcome.kind == .compression else {
            return ProcessingStats(
                originalByteCount: originalByteCount,
                compressedByteCount: compressedByteCount,
                photoCount: photoCount,
                videoCount: videoCount,
                conversionCount: conversionCount + outcome.results.count
            )
        }

        return ProcessingStats(
            originalByteCount: originalByteCount + outcome.results.originalByteCount,
            compressedByteCount: compressedByteCount + outcome.results.outputByteCount,
            photoCount: photoCount + outcome.results.filter { $0.item.kind == .photo }.count,
            videoCount: videoCount + outcome.results.filter { $0.item.kind == .video }.count,
            conversionCount: conversionCount
        )
    }
}
