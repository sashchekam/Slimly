import AVFoundation
import CoreLocation
import Foundation
import Photos
import SlimlyCore
import UIKit

/// Медиатека устройства через PhotoKit.
///
/// Класс, а не актор: PhotoKit сам потокобезопасен и работает колбэками,
/// и заворачивать его в актор значило бы гонять очередь ради очереди.
/// Изменяемого состояния здесь нет вовсе — оно всё у миниатюр, в их
/// собственном загрузчике.
public final class PhotosMediaLibrary: MediaLibrary, @unchecked Sendable {
    private let thumbnails: ThumbnailLoader

    public init(previews: any MediaPreviewRenderer = SystemMediaPreviewRenderer()) {
        thumbnails = ThumbnailLoader(previews: previews)
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
                title: L10n.Library.recents,
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

    /// Выборку система отдаёт целиком, но ассеты в ней ленивые: дорого
    /// не найти файлы, а разобрать каждый — вес PhotoKit сообщает поштучно.
    /// Поэтому фетч без предела, а разбираем только запрошенное окно.
    public func items(in albumID: String, kind: MediaKind?, offset: Int, limit: Int) async -> MediaPage {
        let options = Self.fetchOptions(kind: kind)

        let assets: PHFetchResult<PHAsset>
        if albumID == MediaAlbum.recentID {
            assets = PHAsset.fetchAssets(with: options)
        } else {
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumID],
                options: nil
            )
            guard let collection = collections.firstObject else { return .empty }
            assets = PHAsset.fetchAssets(in: collection, options: options)
        }

        let total = assets.count
        let end = min(offset + limit, total)
        guard offset < end else { return MediaPage(items: [], hasMore: false) }

        var items: [MediaItem] = []
        items.reserveCapacity(end - offset)
        assets.enumerateObjects(at: IndexSet(integersIn: offset ..< end), options: []) { asset, _, _ in
            if let item = Self.item(from: asset) { items.append(item) }
        }
        return MediaPage(items: items, hasMore: end < total)
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

        // Имя и вес берём у исходника: и то и другое пользователь только что
        // видел в системной галерее, и расхождение читалось бы как ошибка.
        let original = originalResource(for: asset)
        let edited = editedResource(for: asset)
        let name = original?.originalFilename ?? "\(asset.localIdentifier.prefix(8)).\(kind == .video ? "mov" : "heic")"
        let type = original?.uniformTypeIdentifier ?? ""

        return MediaItem(
            id: asset.localIdentifier,
            kind: kind,
            fileName: name,
            byteCount: byteCount(of: original, asset: asset, kind: kind),
            sourceByteCount: byteCount(of: edited, asset: asset, kind: kind),
            duration: kind == .video ? .seconds(asset.duration) : nil,
            isHEIC: type == "public.heic" || type == "public.heif" || name.lowercased().hasSuffix(".heic"),
            isLivePhoto: asset.mediaSubtypes.contains(.photoLive),
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            creationDate: asset.creationDate
        )
    }

    /// Файл, каким он лежит в медиатеке, — исходник с камеры.
    /// Его вес и имя показывает системная галерея, их же показываем и мы.
    private static func originalResource(for asset: PHAsset) -> PHAssetResource? {
        resource(for: asset, preferring: asset.mediaType == .video
            ? [.video, .fullSizeVideo]
            : [.photo, .fullSizePhoto])
    }

    /// Файл, который уходит в обработку: у отредактированного медиа это
    /// рендер правок. Пользователь ждёт обратно своё обрезанное видео,
    /// а не полную версию, которую он в галерее уже не видит.
    private static func editedResource(for asset: PHAsset) -> PHAssetResource? {
        resource(for: asset, preferring: asset.mediaType == .video
            ? [.fullSizeVideo, .video]
            : [.fullSizePhoto, .photo])
    }

    private static func resource(
        for asset: PHAsset,
        preferring order: [PHAssetResourceType]
    ) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
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
        await thumbnails.thumbnail(for: item, size: size)
    }

    public func thumbnails(for item: MediaItem, size: Int) -> AsyncStream<Data> {
        thumbnails.thumbnails(for: item, size: size)
    }

    // MARK: Файлы

    public func exportOriginal(_ item: MediaItem) async throws -> URL {
        // Файл отдаём копией, а не им самим: обработчик удаляет исходник
        // за собой, и оригинальная страница исчезла бы вместе с ним.
        if let source = item.sourceURL {
            return try Self.copyToWorkDirectory(source)
        }

        guard let asset = Self.asset(for: item.id) else { throw MediaLibraryError.itemNotFound }
        guard let resource = Self.editedResource(for: asset) else {
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

    public func playbackURL(for item: MediaItem) async -> URL? {
        if let source = item.sourceURL { return source }
        guard item.kind == .video, let asset = Self.asset(for: item.id) else { return nil }

        let options = PHVideoRequestOptions()
        // Ролик может лежать только в iCloud — тогда его сначала выкачают.
        options.isNetworkAccessAllowed = true
        // Оригинал, а не отрендеренная версия: сравнивать нужно ровно тот
        // файл, который ушёл в обработку.
        options.version = .current
        options.deliveryMode = .highQualityFormat

        // Наружу отдаём ссылку, а не сам ассет: `AVAsset` не `Sendable`,
        // и разбирать его нужно там же, где он приехал.
        //
        // Композиция вместо файла приходит у слоу-мо и монтажа: играть её
        // напрямую нельзя, а тянуть ради просмотра полный экспорт — незачем.
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, _ in
                continuation.resume(returning: (avAsset as? AVURLAsset)?.url)
            }
        }
    }

    public func saveToLibrary(
        _ file: URL,
        kind: MediaKind,
        inheritingFrom source: MediaItem?
    ) async throws -> String {
        let identifier = IdentifierBox()
        let origin = source.flatMap { Self.asset(for: $0.id) }
        // Читаем до блока изменений: внутрь него ассет пришлось бы тащить
        // через границу изоляции, а дата с координатой переезжают сами.
        let creationDate = origin?.creationDate
        let coordinate = origin?.location?.coordinate

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
            // Дату проставляем явно, а не полагаемся на содержимое файла:
            // EXIF есть только у картинок, а перекодированное видео приезжает
            // без метаданных контейнера — и вставало бы в конец галереи
            // сегодняшним числом вместо места рядом с оригиналом.
            request.creationDate = creationDate
            if let coordinate {
                request.location = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
            identifier.value = request.placeholderForCreatedAsset?.localIdentifier
        }

        guard let value = identifier.value else {
            throw MediaLibraryError.exportFailed(
                L10n.Failure.saveFailed
            )
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

/// Блок изменений PhotoKit — обычное замыкание без изоляции, поэтому
/// результат из него забираем через ссылочную ячейку.
private final class IdentifierBox: @unchecked Sendable {
    var value: String?
}
