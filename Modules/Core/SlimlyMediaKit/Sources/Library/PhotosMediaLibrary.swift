import Foundation
import Photos
import UIKit
import SlimlyCore

/// Медиатека устройства через PhotoKit.
///
/// Класс, а не актор: PhotoKit сам потокобезопасен и работает колбэками,
/// и заворачивать его в актор значило бы гонять очередь ради очереди.
/// Изменяемое состояние здесь только одно — кэш миниатюр, а `NSCache`
/// синхронизирован сам.
public final class PhotosMediaLibrary: MediaLibrary, @unchecked Sendable {
    /// Сколько файлов показываем в сетке.
    ///
    /// Витрина, а не вся библиотека: вес каждого файла приходится спрашивать
    /// у системы поштучно, и на двенадцати тысячах ассетов экран открывался бы
    /// секундами. Альбом и сортировка по дате оставляют нужное сверху.
    private static let fetchLimit = 300

    private let thumbnails = NSCache<NSString, NSData>()

    public init() {
        thumbnails.countLimit = 400
    }

    // MARK: Доступ

    public func access() async -> MediaAccess {
        Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func requestAccess() async -> MediaAccess {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
        return Self.map(status)
    }

    private static func map(_ status: PHAuthorizationStatus) -> MediaAccess {
        switch status {
        case .authorized: .authorized
        case .limited: .limited
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    // MARK: Обзор

    public func snapshot() async -> LibrarySnapshot {
        let options = PHFetchOptions()
        let photos = PHAsset.fetchAssets(with: .image, options: options).count
        let videos = PHAsset.fetchAssets(with: .video, options: options).count

        return LibrarySnapshot(
            photoCount: photos,
            videoCount: videos,
            freeSpace: Self.freeSpace()
        )
    }

    /// «Важное» свободное место, а не сырое: система готова потеснить кэши,
    /// и пользователю показывают именно эту цифру.
    private static func freeSpace() -> Int64 {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage ?? 0
    }

    public func albums(kind: MediaKind?) async -> [MediaAlbum] {
        var result: [MediaAlbum] = [
            MediaAlbum(
                id: MediaAlbum.recentID,
                title: "Недавние",
                itemCount: PHAsset.fetchAssets(with: Self.fetchOptions(kind: kind)).count
            ),
        ]

        for collection in Self.collections() {
            let count = PHAsset.fetchAssets(in: collection, options: Self.fetchOptions(kind: kind)).count
            // Пустые альбомы не показываем: выбирать в них нечего, а список
            // они удлиняют.
            guard count > 0, let title = collection.localizedTitle else { continue }
            result.append(
                MediaAlbum(id: collection.localIdentifier, title: title, itemCount: count)
            )
        }
        return result
    }

    /// Умные альбомы отобраны руками: система знает их десятками, и «Снимки
    /// экрана» рядом с «Анимированными» превратили бы список в свалку.
    private static func collections() -> [PHAssetCollection] {
        let smartSubtypes: [PHAssetCollectionSubtype] = [
            .smartAlbumFavorites,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots,
            .smartAlbumVideos,
            .smartAlbumPanoramas,
            .smartAlbumSlomoVideos,
        ]

        var collections: [PHAssetCollection] = []
        for subtype in smartSubtypes {
            let fetch = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: subtype,
                options: nil
            )
            fetch.enumerateObjects { collection, _, _ in collections.append(collection) }
        }

        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        albums.enumerateObjects { collection, _, _ in collections.append(collection) }
        return collections
    }

    public func items(in albumID: String, kind: MediaKind?) async -> [MediaItem] {
        let options = Self.fetchOptions(kind: kind)
        options.fetchLimit = Self.fetchLimit

        let assets: PHFetchResult<PHAsset>
        if albumID == MediaAlbum.recentID {
            assets = PHAsset.fetchAssets(with: options)
        } else {
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumID],
                options: nil
            )
            guard let collection = collections.firstObject else { return [] }
            assets = PHAsset.fetchAssets(in: collection, options: options)
        }

        var items: [MediaItem] = []
        items.reserveCapacity(assets.count)
        assets.enumerateObjects { asset, _, _ in
            if let item = Self.item(from: asset) { items.append(item) }
        }
        return items
    }

    private static func fetchOptions(kind: MediaKind?) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        switch kind {
        case .photo:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .video:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case nil:
            options.predicate = NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue
            )
        }
        return options
    }

    // MARK: Разбор ассета

    private static func item(from asset: PHAsset) -> MediaItem? {
        let kind: MediaKind
        switch asset.mediaType {
        case .image: kind = .photo
        case .video: kind = .video
        default: return nil
        }

        let resource = primaryResource(for: asset)
        let name = resource?.originalFilename ?? "\(asset.localIdentifier.prefix(8)).\(kind == .video ? "mov" : "heic")"
        let type = resource?.uniformTypeIdentifier ?? ""

        return MediaItem(
            id: asset.localIdentifier,
            kind: kind,
            fileName: name,
            byteCount: byteCount(of: resource, asset: asset, kind: kind),
            duration: kind == .video ? .seconds(asset.duration) : nil,
            isHEIC: type == "public.heic" || type == "public.heif" || name.lowercased().hasSuffix(".heic"),
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight
        )
    }

    /// Ресурс, который считается «самим файлом»: если снимок редактировали,
    /// это отредактированная версия, а не исходник из камеры.
    private static func primaryResource(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        let order: [PHAssetResourceType] = asset.mediaType == .video
            ? [.fullSizeVideo, .video]
            : [.fullSizePhoto, .photo]

        for type in order {
            if let match = resources.first(where: { $0.type == type }) { return match }
        }
        return resources.first
    }

    /// Точный вес файла PhotoKit отдаёт только через `fileSize` ресурса.
    /// Если ключа нет — считаем по разрешению и длительности: приблизительно,
    /// зато экран не покажет «0 МБ».
    private static func byteCount(of resource: PHAssetResource?, asset: PHAsset, kind: MediaKind) -> Int64 {
        if let size = resource?.value(forKey: "fileSize") as? NSNumber {
            return size.int64Value
        }
        switch kind {
        case .photo:
            return Int64(Double(asset.pixelWidth * asset.pixelHeight) * 0.3)
        case .video:
            return Int64(asset.duration * 8 * 1024 * 1024)
        }
    }

    // MARK: Миниатюры

    public func thumbnail(for item: MediaItem, size: Int) async -> Data? {
        let key = "\(item.id)#\(size)" as NSString
        if let cached = thumbnails.object(forKey: key) { return cached as Data }

        // Страница с камеры — обычный файл, а не ассет: PhotoKit о ней
        // не знает, и кадр достаём прямо из него.
        if let source = item.sourceURL {
            guard let data = await MediaPreview.image(at: source, maxPixel: size * 3) else { return nil }
            thumbnails.setObject(data as NSData, forKey: key)
            return data
        }

        guard let asset = Self.asset(for: item.id) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // Размер приходит в пунктах, а PhotoKit ждёт пиксели. Множитель
        // берём максимальный, а не у экрана: спрашивать про экран отсюда
        // значит идти на главный поток ради числа, которое всё равно 2 или 3.
        let side = CGFloat(size) * 3
        let target = CGSize(width: side, height: side)

        let image: UIImage? = await withCheckedContinuation { continuation in
            let box = ResumeBox(continuation)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: target,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Система вправе позвать обработчик дважды — сначала
                // с временной картинкой. Продолжение возобновляем один раз.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
                guard !isDegraded || image == nil else { return }
                box.resume(with: image)
            }
        }

        guard let data = image?.jpegData(compressionQuality: 0.85) else { return nil }
        thumbnails.setObject(data as NSData, forKey: key)
        return data
    }

    // MARK: Файлы

    public func exportOriginal(_ item: MediaItem) async throws -> URL {
        // Файл отдаём копией, а не им самим: обработчик удаляет исходник
        // за собой, и оригинальная страница исчезла бы вместе с ним.
        if let source = item.sourceURL {
            return try Self.copyToWorkDirectory(source)
        }

        guard let asset = Self.asset(for: item.id) else { throw MediaLibraryError.itemNotFound }
        guard let resource = Self.primaryResource(for: asset) else {
            throw MediaLibraryError.originalUnavailable
        }

        let directory = Self.sourceDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let ext = (resource.originalFilename as NSString).pathExtension
        let url = directory.appendingPathComponent("\(UUID().uuidString).\(ext.isEmpty ? "dat" : ext)")

        let options = PHAssetResourceRequestOptions()
        // Файл может лежать только в iCloud — тогда его сначала выкачают.
        options.isNetworkAccessAllowed = true

        do {
            try await PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: url,
                options: options
            )
        } catch {
            throw MediaLibraryError.exportFailed(error.localizedDescription)
        }
        return url
    }

    public func saveToLibrary(_ file: URL, kind: MediaKind) async throws -> String {
        let identifier = IdentifierBox()

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            // Файл нужен нам и после сохранения — для сравнения «до / после».
            options.shouldMoveFile = false
            request.addResource(
                with: kind == .video ? .video : .photo,
                fileURL: file,
                options: options
            )
            identifier.value = request.placeholderForCreatedAsset?.localIdentifier
        }

        guard let value = identifier.value else {
            throw MediaLibraryError.exportFailed("Не удалось сохранить файл в медиатеку")
        }
        return value
    }

    public func deleteOriginals(_ items: [MediaItem]) async throws {
        // Страницы с камеры в медиатеке не лежат — удалять там нечего.
        let identifiers = items.filter { $0.sourceURL == nil }.map(\.id)
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        guard assets.count > 0 else { return }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }

    private static func asset(for id: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }

    /// Копия файла там же, куда ложатся выгруженные из медиатеки оригиналы:
    /// дальше по цепочке разницы между ними уже нет.
    private static func copyToWorkDirectory(_ source: URL) throws -> URL {
        let directory = sourceDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let ext = source.pathExtension.isEmpty ? "dat" : source.pathExtension
        let url = directory.appendingPathComponent("\(UUID().uuidString).\(ext)")
        do {
            try FileManager.default.copyItem(at: source, to: url)
        } catch {
            throw MediaLibraryError.exportFailed(error.localizedDescription)
        }
        return url
    }

    private static var sourceDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SlimlySource", isDirectory: true)
    }
}

/// Однократное возобновление продолжения: PhotoKit зовёт обработчик
/// миниатюры столько раз, сколько сочтёт нужным.
private final class ResumeBox: @unchecked Sendable {
    private let continuation: CheckedContinuation<UIImage?, Never>
    private let lock = NSLock()
    private var isResumed = false

    init(_ continuation: CheckedContinuation<UIImage?, Never>) {
        self.continuation = continuation
    }

    func resume(with image: UIImage?) {
        lock.lock()
        defer { lock.unlock() }
        guard !isResumed else { return }
        isResumed = true
        continuation.resume(returning: image)
    }
}

/// Блок изменений PhotoKit — обычное замыкание без изоляции, поэтому
/// результат из него забираем через ссылочную ячейку.
private final class IdentifierBox: @unchecked Sendable {
    var value: String?
}
