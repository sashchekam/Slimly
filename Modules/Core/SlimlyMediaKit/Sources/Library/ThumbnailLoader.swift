import Photos
import SlimlyCore
import UIKit

/// Миниатюры медиатеки.
///
/// Отдельно от ``PhotosMediaLibrary``, потому что дела у миниатюр свои:
/// кадры приходят порциями, у каждого запроса есть отмена, и всё это
/// живёт под собственными кэшами.
final class ThumbnailLoader: @unchecked Sendable {
    private let cache = ThumbnailCache(limit: 400)
    private let assets = AssetCache(limit: 2000)
    /// Кадр из файла: страница с камеры — не ассет, и миниатюру для неё
    /// система не отдаст.
    private let previews: any MediaPreviewRenderer
    /// Очередь кодирования. Последовательная и одна на медиатеку: кадры так
    /// не обгоняют друг друга, а прокрутка не превращается в десяток
    /// параллельных JPEG.
    private let encoding = DispatchQueue(label: "com.slimly.thumbnails", qos: .userInitiated)
    private let jpeg: any ThumbnailEncoding

    init(previews: any MediaPreviewRenderer, jpeg: any ThumbnailEncoding = ThumbnailEncoder()) {
        self.previews = previews
        self.jpeg = jpeg
    }

    func thumbnail(for item: MediaItem, size: Int) async -> Data? {
        // Ждём чёткий кадр: поток кончается именно им, а грубые по дороге
        // тому, кто просит одну картинку, не нужны.
        var best: Data?
        for await data in thumbnails(for: item, size: size) { best = data }
        return best
    }

    func thumbnails(for item: MediaItem, size: Int) -> AsyncStream<Data> {
        AsyncStream { continuation in
            // На вызывающем потоке — ни строчки работы. Зовут отсюда прокрутку
            // ленты, то есть с главного потока, а PhotoKit и ассет ищет,
            // и первый кадр отдаёт синхронно — прямо там, где его позвали.
            let request = ThumbnailRequest()
            let task = Task.detached(priority: .userInitiated) { [self] in
                await deliver(item: item, size: size, to: continuation, request: request)
            }

            continuation.onTermination = { _ in
                task.cancel()
                request.cancel()
            }
        }
    }

    private func deliver(
        item: MediaItem,
        size: Int,
        to continuation: AsyncStream<Data>.Continuation,
        request: ThumbnailRequest
    ) async {
        let key = "\(item.id)#\(size)"
        if let cached = cache.data(for: key) {
            continuation.yield(cached)
            continuation.finish()
            return
        }

        // Страница с камеры — обычный файл, а не ассет: PhotoKit о ней
        // не знает, и кадр достаём прямо из него. Промежуточных качеств
        // здесь нет — рендер и так один.
        if let source = item.sourceURL {
            if let data = await previews.preview(at: source, maxPixel: size * 3) {
                cache.store(data, for: key)
                continuation.yield(data)
            }
            continuation.finish()
            return
        }

        guard let asset = assets.asset(for: item.id) else {
            continuation.finish()
            return
        }
        request.start(requestImage(for: asset, size: size, key: key, to: continuation))
    }

    private func requestImage(
        for asset: PHAsset,
        size: Int,
        key: String,
        to continuation: AsyncStream<Data>.Continuation
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        // Кадры по мере готовности: первым система отдаёт то, что у неё уже
        // лежит готовым, — мутный, зато сразу. С `highQualityFormat` плитка
        // до конца подготовки оставалась бы пустой.
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // Размер приходит в пунктах, а PhotoKit ждёт пиксели. Множитель
        // берём максимальный, а не у экрана: спрашивать про экран отсюда
        // значит идти на главный поток ради числа, которое всё равно 2 или 3.
        let side = CGFloat(size) * 3

        return PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: side, height: side),
            contentMode: .aspectFill,
            options: options
        ) { [cache, encoding, jpeg] image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
            guard let image else {
                // Чёткого кадра не будет: система отменила запрос или не смогла
                // его выполнить — держать поток открытым больше не на чем.
                if !isDegraded { continuation.finish() }
                return
            }

            // Кадр PhotoKit приносит на главный поток, а перегнать его в JPEG
            // стоит миллисекунд — и так на каждую плитку ленты.
            encoding.async {
                // Черновой кадр жмём слабее: он живёт до следующего колбэка,
                // и лишние миллисекунды кодирования тут дороже килобайтов.
                guard let data = jpeg.data(from: image, quality: isDegraded ? 0.6 : 0.85) else {
                    if !isDegraded { continuation.finish() }
                    return
                }

                if !isDegraded { cache.store(data, for: key) }
                continuation.yield(data)
                if !isDegraded { continuation.finish() }
            }
        }
    }
}

/// Живой запрос миниатюры.
///
/// Идентификатор PhotoKit возвращает только после того, как запрос начат,
/// а отменить его просят раньше: плитка уезжает с экрана быстрее, чем
/// система успевает ответить. Ячейка сводит эти два момента.
private final class ThumbnailRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var id: PHImageRequestID?
    private var isCancelled = false

    func start(_ id: PHImageRequestID) {
        lock.lock()
        let cancelled = isCancelled
        if !cancelled { self.id = id }
        lock.unlock()

        if cancelled { PHImageManager.default().cancelImageRequest(id) }
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let pending = id
        id = nil
        lock.unlock()

        if let pending { PHImageManager.default().cancelImageRequest(pending) }
    }
}

/// Готовые кадры. `NSCache` синхронизирован сам, но `Sendable` не объявляет —
/// обёртка утверждает это за него, иначе кадр не сложить из колбэка PhotoKit.
private final class ThumbnailCache: @unchecked Sendable {
    private let storage = NSCache<NSString, NSData>()

    init(limit: Int) {
        storage.countLimit = limit
    }

    func data(for key: String) -> Data? {
        storage.object(forKey: key as NSString) as Data?
    }

    func store(_ data: Data, for key: String) {
        storage.setObject(data as NSData, forKey: key as NSString)
    }
}

/// Ассеты по идентификатору: лента спрашивает миниатюры у одних и тех же
/// файлов снова и снова, а каждый поиск — обращение к базе Фото.
///
/// Только для миниатюр: выгрузка оригинала и сохранение работают с ассетом
/// как он есть сейчас, и подсовывать им запомненный объект незачем.
private final class AssetCache: @unchecked Sendable {
    private let storage = NSCache<NSString, PHAsset>()

    init(limit: Int) {
        storage.countLimit = limit
    }

    func asset(for id: String) -> PHAsset? {
        if let cached = storage.object(forKey: id as NSString) { return cached }
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }
        storage.setObject(asset, forKey: id as NSString)
        return asset
    }
}
