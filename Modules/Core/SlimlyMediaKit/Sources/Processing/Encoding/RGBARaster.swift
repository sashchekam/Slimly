import CoreGraphics
import Foundation

/// Цвет RGBA одним словом.
///
/// Упакованным он дёшево ложится и в множество, и в ключ таблицы поиска,
/// а на неё при разложении кадра по палитре приходится по обращению
/// на каждый пиксель.
struct PackedColor: Hashable, Sendable {
    let bits: UInt32

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        bits = UInt32(red) << 24 | UInt32(green) << 16 | UInt32(blue) << 8 | UInt32(alpha)
    }

    var red: UInt8 { UInt8(truncatingIfNeeded: bits >> 24) }
    var green: UInt8 { UInt8(truncatingIfNeeded: bits >> 16) }
    var blue: UInt8 { UInt8(truncatingIfNeeded: bits >> 8) }
    var alpha: UInt8 { UInt8(truncatingIfNeeded: bits) }

    var isOpaque: Bool { alpha == 255 }

    /// Канал по номеру — так по осям ходит медианное сечение,
    /// которому всё равно, какой именно канал оказался самым длинным.
    func component(_ axis: Int) -> UInt8 {
        switch axis {
        case 0: red
        case 1: green
        case 2: blue
        default: alpha
        }
    }
}

/// Развёрнутый кадр: четыре байта на пиксель, строки сверху вниз,
/// выравнивания строк нет.
///
/// Альфа прямая, не предумноженная: в индексированном PNG она хранится
/// отдельным чанком, и вмешивать её в цвет нельзя.
struct RGBARaster {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    var pixelCount: Int { width * height }
}

extension RGBARaster {
    /// - Returns: `nil`, если кадр не удалось развернуть в битмап.
    init?(_ image: CGImage) {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let base = buffer.baseAddress,
                let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        // CoreGraphics рисует только в предумноженную альфу, а PNG хранит
        // прямую — возвращаем компонентам исходный масштаб.
        Self.unpremultiply(&pixels)
        self.init(width: width, height: height, pixels: pixels)
    }

    private static func unpremultiply(_ pixels: inout [UInt8]) {
        pixels.withUnsafeMutableBufferPointer { buffer in
            var index = 0
            while index < buffer.count {
                let alpha = Int(buffer[index + 3])
                // Непрозрачный пиксель уже в прямом масштабе, а полностью
                // прозрачный нечего и делить: цвета под ним не осталось.
                if alpha > 0, alpha < 255 {
                    for offset in 0 ..< 3 {
                        let value = Int(buffer[index + offset]) * 255 + alpha / 2
                        buffer[index + offset] = UInt8(min(255, value / alpha))
                    }
                }
                index += 4
            }
        }
    }
}
