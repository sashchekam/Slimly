import Foundation

/// Доступ к медиатеке устройства.
///
/// Намеренно узкий протокол: система отдаёт количества и свободное место,
/// но не общий вес библиотеки — поэтому такого метода здесь нет.
public protocol MediaLibrary: Sendable {
    func snapshot() async -> LibrarySnapshot
    func recentItems(limit: Int) async -> [MediaItem]
}

/// Заглушка для запуска без доступа к Фото.
public actor StubMediaLibrary: MediaLibrary {
    private let items: [MediaItem]
    private let librarySnapshot: LibrarySnapshot

    public init() {
        items = [
            MediaItem(id: "v1", kind: .video, fileName: "IMG_4821.MOV", byteCount: .megabytes(186), duration: .seconds(42)),
            MediaItem(id: "p1", kind: .photo, fileName: "IMG_4822.HEIC", byteCount: .megabytes(4.1), isHEIC: true),
            MediaItem(id: "p2", kind: .photo, fileName: "IMG_4823.HEIC", byteCount: .megabytes(3.6), isHEIC: true),
            MediaItem(id: "v2", kind: .video, fileName: "IMG_4826.MOV", byteCount: .megabytes(612), duration: .seconds(135)),
            MediaItem(id: "p3", kind: .photo, fileName: "IMG_4830.JPG", byteCount: .megabytes(6.2)),
            MediaItem(id: "v3", kind: .video, fileName: "IMG_4834.MOV", byteCount: .megabytes(74), duration: .seconds(18)),
            MediaItem(id: "p4", kind: .photo, fileName: "IMG_4839.HEIC", byteCount: .megabytes(5.4), isHEIC: true),
            MediaItem(id: "p5", kind: .photo, fileName: "IMG_4841.HEIC", byteCount: .megabytes(2.9), isHEIC: true),
            MediaItem(id: "v4", kind: .video, fileName: "IMG_4845.MOV", byteCount: .megabytes(298), duration: .seconds(67)),
        ]
        librarySnapshot = LibrarySnapshot(
            photoCount: 12_480,
            videoCount: 640,
            freeSpace: .gigabytes(18.2)
        )
    }

    public func snapshot() -> LibrarySnapshot { librarySnapshot }

    public func recentItems(limit: Int) -> [MediaItem] { Array(items.prefix(limit)) }
}

public extension Int64 {
    static func megabytes(_ value: Double) -> Int64 { Int64(value * 1024 * 1024) }
    static func gigabytes(_ value: Double) -> Int64 { Int64(value * 1024 * 1024 * 1024) }
}
