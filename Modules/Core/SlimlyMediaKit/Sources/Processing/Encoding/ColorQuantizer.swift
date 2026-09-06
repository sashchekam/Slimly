import Foundation

/// Кадр, разложенный по палитре.
struct IndexedBitmap {
    let width: Int
    let height: Int
    /// Не длиннее 256 записей: столько цветов помещается в палитру PNG.
    let palette: [PackedColor]
    /// По индексу палитры на пиксель, строки сверху вниз.
    let indices: [UInt8]
}

/// Кадр → палитра не длиннее заданной.
protocol ColorQuantizing: Sendable {
    /// - Parameter colors: сколько цветов оставить, 2…256.
    func indexed(_ raster: RGBARaster, colors: Int) -> IndexedBitmap
}

/// Медианное сечение: цветовое облако кадра делится пополам по самому
/// длинному каналу, пока коробок не станет столько, сколько нужно цветов.
///
/// Плоская графика попадает в палитру без потерь: у логотипа и иконки
/// исходных цветов меньше её длины, и она берётся как есть. Фотография
/// и скриншот приближаются, и это честное приближение: именно им PNG
/// и «сжимают», другого рычага у формата без потерь нет.
struct MedianCutQuantizer: ColorQuantizing {
    /// Точность гистограммы: пять бит на каждый из четырёх каналов.
    ///
    /// Миллион корзин — это четыре мегабайта счётчиков и проход по массиву
    /// вместо словаря на двенадцати мегапикселях. Три потерянных бита всё
    /// равно ушли бы в усреднение по коробке, а по альфе они и того дешевле:
    /// у края с прозрачностью ступень в четыре единицы глазом не берётся.
    private enum Grid {
        static let steps = 32
        static let shift = 3
        static let count = steps * steps * steps * steps
    }

    /// Цвет с числом пикселей, которые в нём сошлись.
    private struct Sample {
        let color: PackedColor
        let count: Int
    }

    /// Отрезок отсортированных образцов — коробка медианного сечения.
    private struct Box {
        let range: Range<Int>
        let color: PackedColor
        let count: Int
        /// Канал, по которому коробка длиннее всего: по нему её и режут.
        let axis: Int
        let extent: Int

        /// Однопиксельную и одноцветную коробку резать нечем.
        var isSplittable: Bool { extent > 0 && range.count > 1 }
        /// Что резать раньше: широкую коробку с большим числом пикселей.
        var priority: Int { extent * count }
    }

    func indexed(_ raster: RGBARaster, colors: Int) -> IndexedBitmap {
        let limit = min(max(colors, 2), 256)

        if let exact = exactPalette(of: raster, limit: limit) {
            return IndexedBitmap(
                width: raster.width,
                height: raster.height,
                palette: exact,
                indices: exactIndices(of: raster, palette: exact)
            )
        }

        let palette = palette(of: raster, colors: limit)
        return IndexedBitmap(
            width: raster.width,
            height: raster.height,
            palette: palette,
            indices: nearestIndices(of: raster, palette: palette)
        )
    }

    // MARK: Точная палитра

    /// Все цвета кадра, если их не больше `limit`.
    ///
    /// Ради этой ветки всё и затевалось: логотип, иконка и скриншот
    /// с плоской заливкой ложатся в палитру ровно теми цветами, что были,
    /// и «сжатие» не сдвигает ни одного пикселя.
    private func exactPalette(of raster: RGBARaster, limit: Int) -> [PackedColor]? {
        var seen = Set<UInt32>(minimumCapacity: limit * 2)
        var palette: [PackedColor] = []

        for index in stride(from: 0, to: raster.pixels.count, by: 4) {
            let color = raster.color(at: index)
            guard seen.insert(color.bits).inserted else { continue }
            guard palette.count < limit else { return nil }
            palette.append(color)
        }
        return palette
    }

    // MARK: Медианное сечение

    private func palette(of raster: RGBARaster, colors: Int) -> [PackedColor] {
        var samples = histogram(of: raster)
        guard !samples.isEmpty else { return [PackedColor(red: 0, green: 0, blue: 0, alpha: 0)] }

        var boxes = [box(of: samples, in: 0 ..< samples.count)]

        while boxes.count < colors {
            guard
                let target = boxes.indices
                    .filter({ boxes[$0].isSplittable })
                    .max(by: { boxes[$0].priority < boxes[$1].priority })
            else { break }

            let box = boxes.remove(at: target)
            let (left, right) = split(box, in: &samples)
            boxes.append(left)
            boxes.append(right)
        }

        return boxes.map(\.color)
    }

    /// Счётчики по корзинам сетки — из них и складывается цветовое облако.
    private func histogram(of raster: RGBARaster) -> [Sample] {
        // Счётчик по корзине не бывает больше числа пикселей, а кадр
        // к этому шагу уже вписан в предел длинной стороны.
        var counts = [Int32](repeating: 0, count: Grid.count)

        raster.pixels.withUnsafeBufferPointer { pixels in
            var index = 0
            while index < pixels.count {
                let bucket = Self.bucket(
                    red: pixels[index],
                    green: pixels[index + 1],
                    blue: pixels[index + 2],
                    alpha: pixels[index + 3]
                )
                counts[bucket] += 1
                index += 4
            }
        }

        return counts.indices.compactMap { bucket in
            counts[bucket] > 0 ? Sample(color: Self.center(of: bucket), count: Int(counts[bucket])) : nil
        }
    }

    private func box(of samples: [Sample], in range: Range<Int>) -> Box {
        var lower = [UInt8](repeating: .max, count: 4)
        var upper = [UInt8](repeating: .min, count: 4)
        var sums = [Int](repeating: 0, count: 4)
        var total = 0

        for sample in samples[range] {
            total += sample.count
            for axis in 0 ..< 4 {
                let value = sample.color.component(axis)
                lower[axis] = min(lower[axis], value)
                upper[axis] = max(upper[axis], value)
                sums[axis] += Int(value) * sample.count
            }
        }

        // Веса те же, что и у расстояния: коробку, где разъехалась альфа,
        // надо разрезать раньше остальных. Иначе её усреднение затянет
        // дырку в картинке полупрозрачной плёнкой.
        let spans = (0 ..< 4).map { (Int(upper[$0]) - Int(lower[$0])) * Self.spanWeights[$0] }
        let axis = spans.indices.max(by: { spans[$0] < spans[$1] }) ?? 0
        let average = sums.map { UInt8(min(255, total > 0 ? $0 / total : 0)) }

        return Box(
            range: range,
            color: PackedColor(red: average[0], green: average[1], blue: average[2], alpha: average[3]),
            count: total,
            axis: axis,
            extent: spans[axis]
        )
    }

    /// Режем по взвешенной медиане: пополам не по числу цветов,
    /// а по числу пикселей, которые за ними стоят.
    private func split(_ box: Box, in samples: inout [Sample]) -> (Box, Box) {
        let axis = box.axis
        let sorted = samples[box.range].sorted { $0.color.component(axis) < $1.color.component(axis) }
        samples.replaceSubrange(box.range, with: sorted)

        var running = 0
        var pivot = box.range.lowerBound
        for index in box.range {
            running += samples[index].count
            if running * 2 >= box.count {
                pivot = index
                break
            }
        }
        // Обе половины должны быть непустыми, иначе цикл сечения зациклится
        // на коробке, которая не уменьшается.
        pivot = min(max(pivot + 1, box.range.lowerBound + 1), box.range.upperBound - 1)

        return (
            self.box(of: samples, in: box.range.lowerBound ..< pivot),
            self.box(of: samples, in: pivot ..< box.range.upperBound)
        )
    }

    // MARK: Разложение по палитре

    /// Палитра собрана из самих цветов кадра, поэтому каждый пиксель
    /// находит себя в ней точно, а не приближением.
    private func exactIndices(of raster: RGBARaster, palette: [PackedColor]) -> [UInt8] {
        var positions: [UInt32: UInt8] = [:]
        for (index, color) in palette.enumerated() {
            positions[color.bits] = UInt8(index)
        }
        return (0 ..< raster.pixelCount).map { positions[raster.color(at: $0 * 4).bits] ?? 0 }
    }

    /// Разложение с растровым приближением по Флойду — Стейнбергу.
    ///
    /// Ошибку округления пикселя расплёскиваем на соседей справа и снизу.
    /// Без этого палитра кладёт на плавный переход ступеньки, а ступенька
    /// на небе видна куда лучше, чем зерно на его месте.
    private func nearestIndices(of raster: RGBARaster, palette: [PackedColor]) -> [UInt8] {
        var lookup = [Int16](repeating: -1, count: Grid.count)
        var indices = [UInt8](repeating: 0, count: raster.pixelCount)
        // Ошибка лежит в шестнадцатых долях и с запасом по краям строки,
        // чтобы крайним пикселям было кому её отдать.
        let stride = (raster.width + 2) * 3
        var current = [Int](repeating: 0, count: stride)
        var next = [Int](repeating: 0, count: stride)

        for y in 0 ..< raster.height {
            for x in 0 ..< raster.width {
                let pixel = y * raster.width + x
                let offset = pixel * 4
                let slot = (x + 1) * 3

                let wanted = PackedColor(
                    red: Self.clamped(Int(raster.pixels[offset]) + current[slot] / 16),
                    green: Self.clamped(Int(raster.pixels[offset + 1]) + current[slot + 1] / 16),
                    blue: Self.clamped(Int(raster.pixels[offset + 2]) + current[slot + 2] / 16),
                    // Альфу не размываем: зерно по краю прозрачности заметнее
                    // любой ступеньки, которую оно должно было убрать.
                    alpha: raster.pixels[offset + 3]
                )

                let index = nearest(to: wanted, in: palette, lookup: &lookup)
                indices[pixel] = UInt8(index)
                spread(error: wanted, minus: palette[index], slot: slot, into: &current, and: &next)
            }

            swap(&current, &next)
            for index in next.indices { next[index] = 0 }
        }
        return indices
    }

    /// Веса Флойда — Стейнберга: семь шестнадцатых уходят вправо,
    /// остальные девять — в три пикселя следующей строки.
    ///
    /// Разливаем половину ошибки, а не всю. Полная сила стоит дорого: она
    /// засевает зерном ровные заливки, где промах по цвету и так не виден,
    /// и скриншот от неё тяжелеет вчетверо. Половины хватает, чтобы убрать
    /// ступеньки с плавных переходов, а на заливках она почти не слышна.
    private func spread(
        error wanted: PackedColor,
        minus chosen: PackedColor,
        slot: Int,
        into current: inout [Int],
        and next: inout [Int]
    ) {
        for channel in 0 ..< 3 {
            let error = (Int(wanted.component(channel)) - Int(chosen.component(channel))) / 2
            guard error != 0 else { continue }

            current[slot + 3 + channel] += error * 7
            next[slot - 3 + channel] += error * 3
            next[slot + channel] += error * 5
            next[slot + 3 + channel] += error
        }
    }

    private static func clamped(_ value: Int) -> UInt8 {
        UInt8(min(255, max(0, value)))
    }

    /// Ближайший цвет палитры с памятью по корзинам сетки: одна и та же
    /// корзина встречается в кадре тысячи раз, и перебирать палитру
    /// для каждого её пикселя незачем.
    private func nearest(to color: PackedColor, in palette: [PackedColor], lookup: inout [Int16]) -> Int {
        let bucket = Self.bucket(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        if lookup[bucket] >= 0 { return Int(lookup[bucket]) }

        var best = 0
        var bestDistance = Int.max
        for (index, entry) in palette.enumerated() {
            let distance = Self.distance(color, entry)
            if distance < bestDistance {
                bestDistance = distance
                best = index
            }
        }

        lookup[bucket] = Int16(best)
        return best
    }

    /// Во сколько раз разброс канала важнее такого же разброса красного.
    /// Порядок тот же, что у весов расстояния, но без возведения в квадрат:
    /// здесь сравниваются длины, а не их квадраты.
    private static let spanWeights = [2, 3, 2, 4]

    /// Квадрат расстояния с весами восприятия: зелёный глаз различает
    /// лучше синего, а промах по альфе виден сильнее любого промаха
    /// по цвету — прозрачное пятно на месте плотного не спутать ни с чем.
    private static func distance(_ lhs: PackedColor, _ rhs: PackedColor) -> Int {
        let red = Int(lhs.red) - Int(rhs.red)
        let green = Int(lhs.green) - Int(rhs.green)
        let blue = Int(lhs.blue) - Int(rhs.blue)
        let alpha = Int(lhs.alpha) - Int(rhs.alpha)
        return 2 * red * red + 4 * green * green + 3 * blue * blue + 8 * alpha * alpha
    }

    // MARK: Сетка

    private static func bucket(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> Int {
        let red = Int(red) >> Grid.shift
        let green = Int(green) >> Grid.shift
        let blue = Int(blue) >> Grid.shift
        return ((red * Grid.steps + green) * Grid.steps + blue) * Grid.steps + (Int(alpha) >> Grid.shift)
    }

    /// Цвет в середине корзины. Края шкалы точные: чистый чёрный и чистый
    /// белый после округления должны остаться собой.
    private static func center(of bucket: Int) -> PackedColor {
        func step(_ value: Int) -> UInt8 { UInt8(value % Grid.steps * 255 / (Grid.steps - 1)) }

        return PackedColor(
            red: step(bucket / Grid.steps / Grid.steps / Grid.steps),
            green: step(bucket / Grid.steps / Grid.steps),
            blue: step(bucket / Grid.steps),
            alpha: step(bucket)
        )
    }
}

private extension RGBARaster {
    /// - Parameter offset: смещение в байтах, кратное четырём.
    func color(at offset: Int) -> PackedColor {
        PackedColor(
            red: pixels[offset],
            green: pixels[offset + 1],
            blue: pixels[offset + 2],
            alpha: pixels[offset + 3]
        )
    }
}
