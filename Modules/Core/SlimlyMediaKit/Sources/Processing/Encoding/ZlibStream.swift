import Compression
import Foundation

/// Байты в zlib-обёртке — в таком виде их ждёт чанк IDAT.
///
/// Фреймворк Compression отдаёт «голый» deflate по RFC 1951, а PNG требует
/// поток по RFC 1950: два байта заголовка спереди и Adler-32 в хвосте.
enum ZlibStream {
    /// - Returns: `nil`, если упаковать не удалось.
    static func encoded(_ source: [UInt8]) -> [UInt8]? {
        guard !source.isEmpty else { return nil }

        // Запас на случай несжимаемых данных: deflate хранит такие блоками
        // «как есть», и они чуть длиннее исходника.
        let capacity = source.count + source.count / 16 + 64
        var deflated = [UInt8](repeating: 0, count: capacity)

        let written = deflated.withUnsafeMutableBufferPointer { output in
            source.withUnsafeBufferPointer { input -> Int in
                guard let target = output.baseAddress, let bytes = input.baseAddress else { return 0 }
                return compression_encode_buffer(
                    target,
                    capacity,
                    bytes,
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard written > 0 else { return nil }

        var stream: [UInt8] = [0x78, 0x9C]
        stream.append(contentsOf: deflated[0 ..< written])
        stream.append(contentsOf: adler32(source).bigEndianBytes)
        return stream
    }

    /// Сумма считается блоками: остаток берётся раз в 5552 байта — дальше
    /// накопитель мог бы переполниться, а на каждом байте делить дорого.
    private static func adler32(_ bytes: [UInt8]) -> UInt32 {
        var low: UInt32 = 1
        var high: UInt32 = 0
        var index = 0

        while index < bytes.count {
            let end = min(index + 5552, bytes.count)
            for position in index ..< end {
                low &+= UInt32(bytes[position])
                high &+= low
            }
            low %= 65521
            high %= 65521
            index = end
        }
        return high << 16 | low
    }
}

extension UInt32 {
    /// Четыре байта старшим вперёд — порядок, в котором числа лежат в PNG.
    var bigEndianBytes: [UInt8] {
        [
            UInt8(truncatingIfNeeded: self >> 24),
            UInt8(truncatingIfNeeded: self >> 16),
            UInt8(truncatingIfNeeded: self >> 8),
            UInt8(truncatingIfNeeded: self),
        ]
    }
}
