import AudioFeatureInterface
import CompressFeatureInterface
import ConvertFeatureInterface
import HomeFeature
import ScanFeatureInterface
import SlimlyDesignSystem

/// Состав хаба инструментов. Живёт в App: только здесь видны маршруты всех
/// фич сразу — главный экран про соседние модули ничего не знает и получает
/// готовый список.
enum HomeTools {
    static let all: [HomeTool] = [
        HomeTool(
            id: "compress",
            title: "Сжатие",
            subtitle: "Фото и видео",
            icon: .compress,
            route: CompressRoute.picker
        ),
        HomeTool(
            id: "convert-photo",
            title: "Конвертация фото",
            subtitle: "HEIC · JPEG · PNG",
            icon: .photoConvert,
            route: ConvertRoute.picker(.photo)
        ),
        HomeTool(
            id: "convert-video",
            title: "Конвертация видео",
            subtitle: "MOV · MP4 · H.264 / HEVC",
            icon: .videoConvert,
            route: ConvertRoute.picker(.video)
        ),
        HomeTool(
            id: "scan",
            title: "Скан документа",
            subtitle: "Фото или камера → PDF",
            icon: .scan,
            route: ScanRoute.intro
        ),
        HomeTool(
            id: "audio",
            title: "Извлечь звук",
            subtitle: "M4A или WAV из видео",
            icon: .audio,
            route: AudioRoute.picker
        ),
    ]
}
