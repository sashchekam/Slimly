// Рисует первый кадр заставки в PNG: знак с приглушёнными контурами и акцентом
// на нижнем углу — ровно то, с чего стартует `SlimlyLogoMarkAnimation`.
// Картинку показывает системный экран запуска, поэтому анимация продолжается
// с того же кадра, а не проявляется заново.
//
//   swift Tools/GenerateLaunchMark.swift App/Resources/Assets.xcassets/LaunchMark.imageset
//
// Скрипт не входит ни в один таргет: Tuist собирает только `App/Sources/**`
// и `Modules/**`.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Сторона холста в точках. 150 — макетный холст анимации: знак занимает в нём
/// 117, и повёрнутый на 45° укладывается с запасом, ничего не срезая.
let canvas = 150.0
/// Сторона сетки знака — та же, что у `SplashView`.
let markSide = 117.0

let directory = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "LaunchMark.imageset"

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: Double((hex >> 16) & 0xFF) / 255,
        green: Double((hex >> 8) & 0xFF) / 255,
        blue: Double(hex & 0xFF) / 255,
        alpha: 1
    )
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func draw(scale: Double) -> CGImage {
    let side = Int(canvas * scale)

    // Фон рисует сам экран запуска цветом `LaunchBackground`, поэтому холст
    // прозрачный: знак ложится поверх той же заливки, что и на заставке.
    guard let context = CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("не удалось создать графический контекст")
    }

    // Дальше считаем в координатах макета: начало — левый верхний угол, ось Y вниз.
    context.translateBy(x: 0, y: Double(side))
    context.scaleBy(x: 1, y: -1)

    // Пропорции сетки повторяют `SlimlyMarkGrid`: квадраты 30×30 в поле 100×100,
    // центры разведены на 21 от середины, всё вместе повёрнуто на 45°.
    let grid = markSide * scale / 100
    let cell = 30 * grid
    let corner = 8 * grid
    let offset = 21 * grid
    // Повторяет `SlimlyMarkGrid.lineWidth(for:)` вместе с нижней границей.
    let stroke = max(markSide * 5.5 / 100, 2.8) * scale
    // Залитый квадрат в анимации крупнее обведённых — он занимает их внешние габариты.
    let accentCell = 36 * grid
    let accentCorner = 10 * grid

    func square(x: Double, y: Double, cell: Double, corner: Double) -> CGPath {
        CGPath(
            roundedRect: CGRect(
                x: x * offset - cell / 2,
                y: y * offset - cell / 2,
                width: cell,
                height: cell
            ),
            cornerWidth: corner,
            cornerHeight: corner,
            transform: nil
        )
    }

    context.translateBy(x: canvas * scale / 2, y: canvas * scale / 2)
    context.rotate(by: .pi / 4)

    // В первом кадре приглушены все четыре контура: белый верхний загорается
    // только в конце круга, когда акцент возвращается на место.
    context.setLineWidth(stroke)
    context.setStrokeColor(color(0x5B5F80))
    for point in [(1.0, 1.0), (-1.0, 1.0), (-1.0, -1.0), (1.0, -1.0)] {
        context.addPath(square(x: point.0, y: point.1, cell: cell, corner: corner))
    }
    context.strokePath()

    // Акцент стоит на нижнем по экрану углу — с него анимация начинает обход.
    context.setFillColor(color(0x9184D9))
    context.addPath(square(x: 1, y: 1, cell: accentCell, corner: accentCorner))
    context.fillPath()

    guard let image = context.makeImage() else {
        fatalError("не удалось получить растр")
    }

    return image
}

func write(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fatalError("не удалось создать файл \(path)")
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("не удалось записать \(path)")
    }

    print("кадр записан: \(path)")
}

try? FileManager.default.createDirectory(
    atPath: directory,
    withIntermediateDirectories: true
)

for scale in [1.0, 2.0, 3.0] {
    let suffix = scale == 1 ? "" : "@\(Int(scale))x"
    write(draw(scale: scale), to: "\(directory)/LaunchMark\(suffix).png")
}

let contents = """
{
  "images" : [
    { "filename" : "LaunchMark.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "LaunchMark@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "LaunchMark@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""

try? contents.write(toFile: "\(directory)/Contents.json", atomically: true, encoding: .utf8)
