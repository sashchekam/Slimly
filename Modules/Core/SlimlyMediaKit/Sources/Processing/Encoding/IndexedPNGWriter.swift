import Foundation

/// Кадр с палитрой → байты PNG.
///
/// Своя запись нужна потому, что ImageIO палитру не умеет: `CGImageDestination`
/// всегда кладёт truecolor, и картинка из четырёх цветов весит у него столько же,
/// сколько фотография того же размера.
struct IndexedPNGWriter {
    private static let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    /// - Returns: `nil`, если палитра пуста или поток не упаковался.
    func data(from bitmap: IndexedBitmap) -> Data? {
        guard !bitmap.palette.isEmpty, bitmap.width > 0, bitmap.height > 0 else { return nil }

        let sorted = Self.sortedByAlpha(bitmap)
        let depth = Self.bitDepth(for: sorted.palette.count)
        guard let compressed = ZlibStream.encoded(Self.rows(of: sorted, depth: depth)) else { return nil }

        var bytes = Self.signature
        bytes += Self.chunk("IHDR", Self.header(width: sorted.width, height: sorted.height, depth: depth))
        bytes += Self.chunk("PLTE", sorted.palette.flatMap { [$0.red, $0.green, $0.blue] })
        if let transparency = Self.transparency(of: sorted.palette) {
            bytes += Self.chunk("tRNS", transparency)
        }
        bytes += Self.chunk("IDAT", compressed)
        bytes += Self.chunk("IEND", [])
        return Data(bytes)
    }

    // MARK: Палитра

    /// Полупрозрачные записи уезжают в начало палитры.
    ///
    /// Чанк tRNS обрывается на последней непрозрачной записи, поэтому
    /// от порядка зависит его длина: у картинки с одной дыркой в углу
    /// это байт вместо двухсот пятидесяти шести.
    private static func sortedByAlpha(_ bitmap: IndexedBitmap) -> IndexedBitmap {
        let order = bitmap.palette.indices.sorted { bitmap.palette[$0].alpha < bitmap.palette[$1].alpha }
        guard order != Array(bitmap.palette.indices) else { return bitmap }

        var positions = [UInt8](repeating: 0, count: bitmap.palette.count)
        for (position, source) in order.enumerated() {
            positions[source] = UInt8(position)
        }

        return IndexedBitmap(
            width: bitmap.width,
            height: bitmap.height,
            palette: order.map { bitmap.palette[$0] },
            indices: bitmap.indices.map { positions[Int($0)] }
        )
    }

    /// Альфа записей до последней полупрозрачной. Полностью непрозрачной
    /// палитре чанк не нужен вовсе.
    private static func transparency(of palette: [PackedColor]) -> [UInt8]? {
        guard let last = palette.lastIndex(where: { !$0.isOpaque }) else { return nil }
        return palette[0 ... last].map(\.alpha)
    }

    /// Индексу нужно ровно столько бит, сколько занимает длина палитры:
    /// четырёхцветной иконке хватает двух бит на пиксель вместо восьми.
    private static func bitDepth(for colors: Int) -> Int {
        switch colors {
        case ...2: 1
        case ...4: 2
        case ...16: 4
        default: 8
        }
    }

    // MARK: Пиксели

    /// Строки со служебным байтом фильтра в начале каждой.
    ///
    /// Фильтр всегда нулевой: он предсказывает байт по соседям, а у индексов
    /// соседство ничего не значит — разница между «цветом 3» и «цветом 200»
    /// не число, и вычитать их бессмысленно.
    private static func rows(of bitmap: IndexedBitmap, depth: Int) -> [UInt8] {
        let perByte = 8 / depth
        let stride = (bitmap.width + perByte - 1) / perByte
        var rows = [UInt8](repeating: 0, count: bitmap.height * (stride + 1))

        for y in 0 ..< bitmap.height {
            let row = y * (stride + 1) + 1
            for x in 0 ..< bitmap.width {
                let index = bitmap.indices[y * bitmap.width + x]
                guard depth < 8 else {
                    rows[row + x] = index
                    continue
                }
                // Внутри байта индексы лежат старшими битами вперёд.
                let shift = 8 - depth * (x % perByte + 1)
                rows[row + x / perByte] |= index << shift
            }
        }
        return rows
    }

    // MARK: Чанки

    private static func header(width: Int, height: Int, depth: Int) -> [UInt8] {
        UInt32(width).bigEndianBytes
            + UInt32(height).bigEndianBytes
            // Тип цвета 3 — палитра; дальше нулями идут метод сжатия,
            // метод фильтрации и отсутствие чересстрочности.
            + [UInt8(depth), 3, 0, 0, 0]
    }

    private static func chunk(_ type: String, _ payload: [UInt8]) -> [UInt8] {
        let body = Array(type.utf8) + payload
        return UInt32(payload.count).bigEndianBytes + body + crc32(body).bigEndianBytes
    }

    private static let crcTable: [UInt32] = (0 ..< 256).map { index in
        (0 ..< 8).reduce(UInt32(index)) { value, _ in
            value & 1 == 1 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
        }
    }

    private static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var value: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            value = crcTable[Int((value ^ UInt32(byte)) & 0xFF)] ^ (value >> 8)
        }
        return value ^ 0xFFFF_FFFF
    }
}
