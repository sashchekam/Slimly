import Foundation

/// Пресет сжатия. Коэффициент — доля от исходного веса, которая останется.
public enum CompressionPreset: String, CaseIterable, Sendable, Hashable, Identifiable {
    case light
    case medium
    case maximum

    public var id: String { rawValue }

    public var ratio: Double {
        switch self {
        case .light: 0.68
        case .medium: 0.42
        case .maximum: 0.24
        }
    }

    public var title: String {
        switch self {
        case .light: "Лёгкое"
        case .medium: "Среднее"
        case .maximum: "Максимальное"
        }
    }

    public var summary: String {
        switch self {
        case .light: "1080p, почти не отличить от оригинала"
        case .medium: "1080p, битрейт ниже — для мессенджеров и облака"
        case .maximum: "720p, заметнее на крупных деталях"
        }
    }
}

public struct CompressionOptions: Sendable, Hashable {
    public var preset: CompressionPreset
    /// Оригиналы не трогаем во время обработки: удаление — отдельный
    /// системный запрос уже после результата.
    public var keepsOriginals: Bool
    public var savesToAlbum: Bool
    public var convertsHEICToJPEG: Bool

    public init(
        preset: CompressionPreset = .medium,
        keepsOriginals: Bool = true,
        savesToAlbum: Bool = true,
        convertsHEICToJPEG: Bool = true
    ) {
        self.preset = preset
        self.keepsOriginals = keepsOriginals
        self.savesToAlbum = savesToAlbum
        self.convertsHEICToJPEG = convertsHEICToJPEG
    }

    public static let `default` = CompressionOptions()
}

/// Оценка веса «после» до обработки. Считается по коэффициенту пресета,
/// поэтому в интерфейсе всегда подписана как приблизительная.
public enum CompressionEstimate {
    public static func byteCount(for items: some Sequence<MediaItem>, preset: CompressionPreset) -> Int64 {
        Int64(Double(items.totalByteCount) * preset.ratio)
    }
}

public struct CompressionResult: Sendable, Hashable, Identifiable {
    public let item: MediaItem
    public let compressedByteCount: Int64

    public init(item: MediaItem, compressedByteCount: Int64) {
        self.item = item
        self.compressedByteCount = compressedByteCount
    }

    public var id: String { item.id }

    public var savedByteCount: Int64 { item.byteCount - compressedByteCount }

    /// Доля, на которую файл похудел: 0.64 — это «−64%».
    public var reduction: Double {
        guard item.byteCount > 0 else { return 0 }
        return 1 - Double(compressedByteCount) / Double(item.byteCount)
    }
}

public extension Sequence<CompressionResult> {
    var originalByteCount: Int64 { reduce(0) { $0 + $1.item.byteCount } }
    var compressedByteCount: Int64 { reduce(0) { $0 + $1.compressedByteCount } }
    var savedByteCount: Int64 { reduce(0) { $0 + $1.savedByteCount } }
}

public struct ItemProgress: Sendable, Hashable, Identifiable {
    public let id: String
    public let fraction: Double

    public init(id: String, fraction: Double) {
        self.id = id
        self.fraction = fraction
    }
}

public struct CompressionProgress: Sendable, Hashable {
    public let overall: Double
    public let items: [ItemProgress]
    public let estimatedRemaining: Duration

    public init(overall: Double, items: [ItemProgress], estimatedRemaining: Duration) {
        self.overall = overall
        self.items = items
        self.estimatedRemaining = estimatedRemaining
    }

    public func fraction(for item: MediaItem) -> Double {
        items.first { $0.id == item.id }?.fraction ?? 0
    }
}

/// Чем закончилась обработка. Ачивки считает сервис: только он видит
/// состояние базы до и после, а экран результата — уже нет.
public struct CompressionOutcome: Sendable, Hashable {
    public let results: [CompressionResult]
    public let options: CompressionOptions
    public let unlockedAchievements: [Achievement]

    public init(
        results: [CompressionResult],
        options: CompressionOptions,
        unlockedAchievements: [Achievement]
    ) {
        self.results = results
        self.options = options
        self.unlockedAchievements = unlockedAchievements
    }
}

public enum CompressionEvent: Sendable {
    case progress(CompressionProgress)
    case finished(CompressionOutcome)
}
