import Foundation

/// Двухцветная страница из полутоновой: решить про каждый пиксель, чернила
/// это или бумага, и упаковать ответ по биту на пиксель.
protocol PageBinarizing: Sendable {
    func bitmap(from page: GrayscaleBuffer) -> ScannedPage.Bitmap
}

/// Порог Саувола — локальный, со скидкой на разброс яркости вокруг пикселя.
///
/// Один порог на всю страницу (`CIColorThresholdOtsu`, как было раньше)
/// работает, только пока лист освещён ровно. Стоит тени от руки лечь на
/// угол — и тот же порог там съедает текст, а на пересвеченном крае
/// оставляет серый мусор. Локальный порог считается по окну вокруг
/// пикселя и такой страницы не боится.
///
/// Простого «темнее среднего по окну» при этом мало: на пустом поле
/// среднее равно самой бумаге, и половина шума уходит в чернила. Саувола
/// добавляет поправку на разброс — на ровном поле разброса нет, порог
/// проваливается ниже бумаги, и поле остаётся чистым:
///
///     T = m · (1 + k · (s / R − 1))
///
/// где `m` и `s` — среднее и разброс в окне, `R` — половина шкалы яркости.
struct SauvolaBinarizer: PageBinarizing {
    /// Сторона окна как доля длинной стороны страницы. На четырёхстах dpi
    /// это около сорока пикселей — примерно высота строчной буквы, то есть
    /// окно всегда видит и букву, и бумагу вокруг неё.
    private static let sideToWindow = 100
    /// Окно меньше этого бессмысленно: внутри одной жирной буквы среднее
    /// равно самой букве, и она вычитается сама из себя.
    private static let minimumWindow = 15

    func bitmap(from page: GrayscaleBuffer) -> ScannedPage.Bitmap {
        guard page.width > 0, page.height > 0 else { return packed(page) }

        let window = max(Self.minimumWindow, max(page.width, page.height) / Self.sideToWindow)
        var pass = SauvolaPass(page: page, radius: window / 2)

        return packed(GrayscaleBuffer(width: page.width, height: page.height, samples: pass.run()))
    }

    /// Порог уже наложен, и в буфере остались только два значения — здесь
    /// выбрасываются семь лишних бит из каждого байта. Страница ужимается
    /// восьмикратно ещё до того, как PDF дожмёт её Flate; ровно поэтому
    /// двухцветному режиму можно позволить разрешение, которого не выдержал
    /// бы JPEG.
    private func packed(_ mask: GrayscaleBuffer) -> ScannedPage.Bitmap {
        let width = mask.width
        let rowBytes = (width + 7) / 8
        var bits = [UInt8](repeating: 0, count: rowBytes * mask.height)

        for y in 0 ..< mask.height {
            let row = y * rowBytes
            let line = y * width
            for x in 0 ..< width where mask.samples[line + x] >= 128 {
                bits[row + x / 8] |= UInt8(0x80 >> (x % 8))
            }
        }

        return ScannedPage.Bitmap(
            width: width,
            height: mask.height,
            rowBytes: rowBytes,
            bits: Data(bits)
        )
    }
}

/// Один проход порога по странице.
///
/// Состояние живёт ровно одну страницу, поэтому это отдельный объект внутри
/// метода, а не поля воркера. Окно едет по строкам и по столбцам, и суммы
/// в нём не пересчитываются: строка входит в окно, строка выходит — работы
/// на пиксель ровно столько же, сколько при одном общем пороге.
private struct SauvolaPass {
    /// Насколько сильно разброс в окне снижает порог. 0.2 — значение из
    /// исходной статьи: меньше — на бумаге остаётся шум, больше — тонкие
    /// штрихи букв рвутся.
    private static let weight = 0.2
    /// Половина шкалы яркости, она же нормировка разброса.
    private static let range = 128.0

    private let samples: [UInt8]
    private let width: Int
    private let height: Int
    private let radius: Int

    /// Суммы и суммы квадратов по столбцам в текущем вертикальном окне.
    private var columnSum: [Int32]
    private var columnSquares: [Int32]
    private var rowsInWindow = 0

    init(page: GrayscaleBuffer, radius: Int) {
        samples = page.samples
        width = page.width
        height = page.height
        self.radius = radius
        columnSum = [Int32](repeating: 0, count: page.width)
        columnSquares = [Int32](repeating: 0, count: page.width)
    }

    mutating func run() -> [UInt8] {
        var mask = [UInt8](repeating: 0, count: width * height)
        for y in 0 ..< height {
            slide(to: y)
            threshold(row: y, into: &mask)
        }
        return mask
    }

    /// Сдвинуть вертикальное окно на строку вниз.
    private mutating func slide(to y: Int) {
        guard y > 0 else {
            for row in 0 ... min(radius, height - 1) {
                accumulate(row: row, sign: 1)
            }
            return
        }

        let entering = y + radius
        if entering < height {
            accumulate(row: entering, sign: 1)
        }
        let leaving = y - radius - 1
        if leaving >= 0 {
            accumulate(row: leaving, sign: -1)
        }
    }

    private mutating func accumulate(row: Int, sign: Int32) {
        let line = row * width
        for x in 0 ..< width {
            let value = Int32(samples[line + x])
            columnSum[x] += sign * value
            columnSquares[x] += sign * value * value
        }
        rowsInWindow += Int(sign)
    }

    /// Прокатить горизонтальное окно по строке и раздать пикселям порог.
    private func threshold(row y: Int, into mask: inout [UInt8]) {
        let last = width - 1
        var columns = min(radius, last) + 1
        var sum = 0
        var squares = 0
        for x in 0 ..< columns {
            sum += Int(columnSum[x])
            squares += Int(columnSquares[x])
        }

        let line = y * width
        for x in 0 ... last {
            if x > 0 {
                let entering = x + radius
                if entering <= last {
                    sum += Int(columnSum[entering])
                    squares += Int(columnSquares[entering])
                    columns += 1
                }
                let leaving = x - radius - 1
                if leaving >= 0 {
                    sum -= Int(columnSum[leaving])
                    squares -= Int(columnSquares[leaving])
                    columns -= 1
                }
            }

            let count = Double(columns * rowsInWindow)
            let mean = Double(sum) / count
            let deviation = max(0, Double(squares) / count - mean * mean).squareRoot()
            let limit = mean * (1 + Self.weight * (deviation / Self.range - 1))
            mask[line + x] = Double(samples[line + x]) > limit ? 255 : 0
        }
    }
}
