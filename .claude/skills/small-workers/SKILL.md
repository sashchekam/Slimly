---
name: small-workers
description: Разбить сервис на маленькие воркеры за протоколами и внедрить их дефолтными параметрами конструктора. Использовать при написании или доработке любого сервиса, обработчика, парсера, хранилища — и всегда, когда в коде появляется enum со static-методами, синглтон или класс, который делает несколько разных дел сразу.
---

# Маленькие воркеры вместо статики

В Slimly нет «утилитных» enum'ов со `static func`. Любая работа — это объект
за протоколом, который приходит в конструктор параметром со значением
по умолчанию. Тогда состав сервиса виден в его `init`, а подменить любую
часть можно, не трогая остальное.

## Правило

```swift
// ❌ так не делаем
enum ImagePipeline {
    static func write(source: URL, to destination: URL, settings: Settings) throws { … }
}

// ✅ так делаем
protocol ImageEncoding: Sendable {
    func write(source: URL, to destination: URL, settings: ImageEncodingSettings) throws
}

struct ImageEncoder: ImageEncoding {
    private let reader: any ImageSourceReading
    private let metadata: any ImageOutputPropertiesComposing
    private let writer: any ImageDestinationWriting

    init(
        reader: any ImageSourceReading = ImageSourceReader(),
        metadata: any ImageOutputPropertiesComposing = ImageOutputProperties(),
        writer: any ImageDestinationWriting = ImageDestinationWriter()
    ) { … }
}
```

Вызывающая сторона пишет `ImageEncoder()` и не знает про состав. Тест
подставляет свою реализацию любого шага, не поднимая ImageIO целиком.

## Как разбивать

1. Выпиши, что класс делает, глаголами. Каждый глагол — кандидат в воркер.
2. Один воркер — один протокол — один файл. Имя протокола — действие
   (`ImageEncoding`, `VideoTranscoding`, `AudioLegMaking`), имя реализации —
   исполнитель (`ImageEncoder`, `VideoTranscoder`, `AudioLegFactory`).
3. Главный тип после разбора — сборка: он раздаёт работу и не содержит
   ни байта самой работы. `MediaProcessor` держит очередь и прогресс,
   а кодирует `CompressionWorker` через `ImageEncoder` и `VideoTranscoder`.
4. Зависимости — `private let` c типом `any Protocol`, приходят в `init`
   значением по умолчанию. Никаких `AppContainer`, синглтонов и `shared`.
5. Состояние, живущее одну операцию, не поле воркера, а отдельный объект
   внутри метода: `SampleTransfer` — воркер без состояния, `TransferSession`
   внутри него — одна перекачка.

## Границы модулей

- Протокол внутренний (`protocol`, без `public`), если воркер не пересекает
  границу модуля. Публичны только контракты в `SlimlyCore`.
- У публичного типа `public init()` собирает состав по умолчанию, а рядом
  лежит внутренний `init(...)` с воркерами: public-инициализатор не может
  принимать internal-типы.

```swift
public struct SystemMediaPreviewRenderer: MediaPreviewRenderer {
    public init() {
        self.init(images: ImageFrameExtractor(), videos: VideoFrameExtractor())
    }

    init(images: any ImageFrameExtracting, videos: any VideoFrameExtracting) { … }
}
```

- У класса ради этого делают `public convenience init`, а designated-init
  остаётся внутренним — так собран `MediaProcessor`.

## Когда статика допустима

- Расширения типов-значений: `ImageFormat.matching(fileExtension:)`,
  `VideoCodec.avCodec` — это мэппинг типа на себя, подменять там нечего.
- `private static let` — константа внутри воркера (порог, доля, лимит).
  В Swift 6 она обязана быть `Sendable`: `[String: Any]` статикой не сделать,
  такую константу выносим в вычисляемое свойство.

## Чек-лист перед завершением

- [ ] В `Sources` нет `enum` со `static func`, кроме мэпперов форматов.
- [ ] У каждого воркера есть протокол, и вызывающая сторона держит `any …`.
- [ ] Все зависимости видны в `init` и имеют значение по умолчанию.
- [ ] Тип не превышает ~150 строк; иначе внутри него ещё один воркер.
- [ ] `swiftlint lint --strict --quiet` молчит (следит и за числом
      параметров: больше пяти — заводи структуру настроек).

Образец разбора целиком — `Modules/Core/SlimlyMediaKit/Sources/Processing`:
`Encoding`, `Video`, `Output`, `Pipeline`, `Preview`, `Playback`.
