// Рисует иконку приложения в PNG: тот же знак, что и `SlimlyLogoMark`,
// но растром — в каталог ассетов вектор не положишь.
//
//   swift Tools/GenerateAppIcon.swift App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// Скрипт не входит ни в один таргет: Tuist собирает только `App/Sources/**`
// и `Modules/**`.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024.0
let output = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: Double((hex >> 16) & 0xFF) / 255,
        green: Double((hex >> 8) & 0xFF) / 255,
        blue: Double(hex & 0xFF) / 255,
        alpha: 1
    )
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

// Иконку App Store не принимает с альфа-каналом, поэтому контекст непрозрачный.
guard let context = CGContext(
    data: nil,
    width: Int(side),
    height: Int(side),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: space,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("не удалось создать графический контекст")
}

// Дальше считаем в координатах макета: начало — левый верхний угол, ось Y вниз.
context.translateBy(x: 0, y: side)
context.scaleBy(x: 1, y: -1)

// MARK: Фон

// Пятно света сдвинуто к левому верхнему углу — так же, как на экранах
// приложения, иначе иконка и первый экран выглядят из разных наборов.
let backdrop = CGGradient(
    colorsSpace: space,
    colors: [color(0x2F3350), color(0x15172A)] as CFArray,
    locations: [0, 0.72]
)!

context.saveGState()
context.clip(to: CGRect(x: 0, y: 0, width: side, height: side))
// Эллипс рисуем единичной окружностью в растянутой системе координат:
// у CoreGraphics радиальный градиент всегда круглый.
context.translateBy(x: side * 0.3, y: 0)
context.scaleBy(x: side * 1.2, y: side)
context.drawRadialGradient(
    backdrop,
    startCenter: .zero,
    startRadius: 0,
    endCenter: .zero,
    endRadius: 1,
    options: .drawsAfterEndLocation
)
context.restoreGState()

// MARK: Знак

// Пропорции сетки повторяют `SlimlyLogoMark`: квадраты 30×30 в поле 100×100,
// центры разведены на 21 от середины, всё вместе повёрнуто на 45°.
let markSide = side * 128 / 220
let scale = markSide / 100
let cell = 30 * scale
let corner = 8 * scale
let offset = 21 * scale
let stroke = 5.5 * scale

func square(x: CGFloat, y: CGFloat) -> CGPath {
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

context.saveGState()
context.translateBy(x: side / 2, y: side / 2)
context.rotate(by: .pi / 4)
context.setLineWidth(stroke)

context.setStrokeColor(color(0xE9E9ED))
context.addPath(square(x: -1, y: -1))
context.strokePath()

context.setStrokeColor(color(0x5B5F80))
context.addPath(square(x: 1, y: -1))
context.addPath(square(x: -1, y: 1))
context.strokePath()

context.setFillColor(color(0x9184D9))
context.addPath(square(x: 1, y: 1))
context.fillPath()

context.restoreGState()

// MARK: Запись

guard let image = context.makeImage() else {
    fatalError("не удалось получить растр")
}

let url = URL(fileURLWithPath: output)
guard let destination = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fatalError("не удалось создать файл \(output)")
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("не удалось записать \(output)")
}

print("иконка записана: \(output)")
