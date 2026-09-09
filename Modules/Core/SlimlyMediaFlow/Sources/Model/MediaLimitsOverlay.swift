import Foundation
import SlimlyCore

/// Пределы, заданные в конфиге, — ровно те, что в объекте написаны.
///
/// В консоли под каждый тариф лежит объект вида:
///
/// ```json
/// { "compress_files": 5, "convert_photos": 5, "convert_videos": 3,
///   "audio_videos": 3, "scan_pages": 5 }
/// ```
///
/// Поля необязательные, потому что правят их обычно не все сразу: «поднять
/// скану страницы» — это одно поле, и остальные четыре должны остаться
/// такими, какими их задал тариф, а не съехать на чужие.
struct MediaLimitsOverlay: JSONRemoteConfigValue {
    var compressFiles: Int?
    var convertPhotos: Int?
    var convertVideos: Int?
    var audioVideos: Int?
    var scanPages: Int?

    init() { }

    init(from decoder: any Decoder) throws {
        let json = try decoder.container(keyedBy: CodingKeys.self)

        compressFiles = Self.limit(json, .compressFiles)
        convertPhotos = Self.limit(json, .convertPhotos)
        convertVideos = Self.limit(json, .convertVideos)
        audioVideos = Self.limit(json, .audioVideos)
        scanPages = Self.limit(json, .scanPages)
    }

    /// `nil` — поля нет или в нём не число: такому полю остаётся предел
    /// тарифа, а не промах в наборе. Прочитанное зажимается в границы,
    /// за которыми оно уже не предел: шаг выбора без единого файла или
    /// пачка, которой не хватит ни памяти, ни терпения.
    private static func limit(_ json: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        guard let value = try? json.decode(Int.self, forKey: key) else { return nil }

        return min(max(value, allowed.lowerBound), allowed.upperBound)
    }

    private static let allowed = 1...50

    enum CodingKeys: String, CodingKey {
        case compressFiles = "compress_files"
        case convertPhotos = "convert_photos"
        case convertVideos = "convert_videos"
        case audioVideos = "audio_videos"
        case scanPages = "scan_pages"
    }
}

extension RemoteConfigKey where Value == MediaLimitsOverlay {
    static var mediaLimits: RemoteConfigKey { RemoteConfigKey("media_limits", default: MediaLimitsOverlay()) }

    /// У подписки свой ключ, а не поле внутри общего объекта: тарифы правят
    /// порознь и в разное время, и промах в одном не должен утаскивать
    /// за собой другой.
    static var mediaLimitsPro: RemoteConfigKey { RemoteConfigKey("media_limits_pro", default: MediaLimitsOverlay()) }
}
