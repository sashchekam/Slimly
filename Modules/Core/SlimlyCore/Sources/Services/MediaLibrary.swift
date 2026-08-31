import Foundation

/// Что система разрешила делать с медиатекой.
public enum MediaAccess: Sendable, Hashable {
    case notDetermined
    case denied
    /// Пользователь выдал доступ к части файлов — работать можно, но
    /// показываем мы только отобранное им.
    case limited
    case authorized

    public var allowsBrowsing: Bool {
        self == .authorized || self == .limited
    }
}

public enum MediaLibraryError: LocalizedError, Sendable {
    case accessDenied
    case itemNotFound
    /// Оригинал лежит в iCloud, а не на устройстве.
    case originalUnavailable
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied: "Нет доступа к медиатеке"
        case .itemNotFound: "Файл не найден в медиатеке"
        case .originalUnavailable: "Оригинал не выгружен из iCloud"
        case let .exportFailed(reason): reason
        }
    }
}

/// Доступ к медиатеке устройства.
///
/// Здесь и просмотр, и выдача оригиналов обработчику: и то и другое —
/// работа с одними и теми же ассетами, и разделять их значило бы дважды
/// спрашивать систему об одном и том же. Общего веса медиатеки iOS
/// не сообщает, поэтому такого метода нет и быть не может.
/// Вид файлов задаёт инструмент: конвертеру видео нечего показывать фото.
public protocol MediaLibrary: Sendable {
    func access() async -> MediaAccess
    /// Спросить доступ. Системный запрос показывается один раз за установку,
    /// дальше метод просто возвращает текущий статус.
    func requestAccess() async -> MediaAccess

    func snapshot() async -> LibrarySnapshot
    func albums(kind: MediaKind?) async -> [MediaAlbum]
    func items(in albumID: String, kind: MediaKind?) async -> [MediaItem]

    /// Миниатюра в JPEG. Данные, а не картинка, — чтобы модель не зависела
    /// от UIKit и спокойно ездила между акторами.
    func thumbnail(for item: MediaItem, size: Int) async -> Data?

    /// Копия оригинала во временной папке — источник для обработки.
    /// Удалять её должен тот, кто заказал: система за нами не убирает.
    func exportOriginal(_ item: MediaItem) async throws -> URL

    /// Ссылка на оригинал для воспроизведения.
    ///
    /// В отличие от ``exportOriginal(_:)`` файл не копируется: плееру хватает
    /// того, что уже лежит в медиатеке. `nil` — если играть нечего: ассета
    /// нет, это не видео или система не отдала файл.
    func playbackURL(for item: MediaItem) async -> URL?

    /// Положить готовый файл в медиатеку. Возвращает идентификатор
    /// созданного ассета.
    func saveToLibrary(_ file: URL, kind: MediaKind) async throws -> String

    /// Удалить оригиналы. iOS показывает собственный запрос подтверждения,
    /// поэтому своего мы не рисуем.
    func deleteOriginals(_ items: [MediaItem]) async throws
}
