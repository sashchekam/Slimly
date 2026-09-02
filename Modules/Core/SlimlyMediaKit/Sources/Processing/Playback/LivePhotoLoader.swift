import Foundation
import Photos

/// Ссылочная ячейка вокруг `PHLivePhoto`: сам тип не `Sendable`, а забрать
/// его нужно из колбэка PhotoKit в главный актор.
final class LivePhotoBox: @unchecked Sendable {
    let value: PHLivePhoto

    init(_ value: PHLivePhoto) {
        self.value = value
    }
}

/// Живое фото по идентификатору ассета.
///
/// Ассет ищем здесь, а не в медиатеке: живое фото — это пара «кадр + ролик»
/// внутри PhotoKit, и ссылки на файл, которую можно было бы отдать плееру
/// через протокол медиатеки, у него нет.
protocol LivePhotoLoading: Sendable {
    func livePhoto(id: String) async -> LivePhotoBox?
}

struct PhotoKitLivePhotoLoader: LivePhotoLoading {
    func livePhoto(id: String) async -> LivePhotoBox? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }

        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            let box = LivePhotoResumeBox(continuation)
            PHImageManager.default().requestLivePhoto(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { photo, info in
                // Как и с миниатюрами, система вправе позвать обработчик
                // дважды — сначала с черновым вариантом.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
                guard !isDegraded || photo == nil else { return }
                box.resume(with: photo.map(LivePhotoBox.init))
            }
        }
    }
}

/// Однократное возобновление продолжения: PhotoKit зовёт обработчик столько
/// раз, сколько сочтёт нужным, а продолжение принимает ответ один.
private final class LivePhotoResumeBox: @unchecked Sendable {
    private let continuation: CheckedContinuation<LivePhotoBox?, Never>
    private let lock = NSLock()
    private var isResumed = false

    init(_ continuation: CheckedContinuation<LivePhotoBox?, Never>) {
        self.continuation = continuation
    }

    func resume(with box: LivePhotoBox?) {
        lock.lock()
        defer { lock.unlock() }
        guard !isResumed else { return }
        isResumed = true
        continuation.resume(returning: box)
    }
}
