import SlimlyDesignSystem
import SwiftUI

/// Страница в рамке, по ней сверху вниз идёт линия сканера.
struct ScanIllustration: View {
    private struct Phase {
        var position = 0.06
        var opacity = 0.0
    }

    private static let page = CGSize(width: 158, height: 210)

    var body: some View {
        KeyframeAnimator(initialValue: Phase(), repeating: true) { phase in
            page
                .overlay(alignment: .top) {
                    scanLine
                        .opacity(phase.opacity)
                        .offset(y: Self.page.height * phase.position)
                }
                .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.sm, style: .continuous))
                .slimlyElevation(.lg, cornerRadius: SlimlyRadius.sm)
                // Рамка идёт по внешнему краю листа, а не по нему самому:
                // так видно, что границы уже найдены, а не дорисованы поверх.
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(SlimlyColor.accent, lineWidth: 2)
                        .padding(-3)
                }
        } keyframes: { _ in
            KeyframeTrack(\.position) {
                LinearKeyframe(0.92, duration: 2.2)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(1, duration: 0.26)
                LinearKeyframe(1, duration: 1.67)
                LinearKeyframe(0, duration: 0.27)
            }
        }
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextLine(width: 0.58, height: 8, isHeading: true)
            TextLine(width: 1, height: 4, isHeading: false)
            TextLine(width: 0.92, height: 4, isHeading: false)
            TextLine(width: 0.96, height: 4, isHeading: false)
            TextLine(width: 0.64, height: 4, isHeading: false)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(width: Self.page.width, height: Self.page.height, alignment: .top)
        .background(PaperSurface())
    }

    private var scanLine: some View {
        Rectangle()
            .fill(SlimlyColor.accent)
            .frame(height: 2)
            .shadow(color: SlimlyColor.accent.opacity(0.55), radius: 9)
    }
}

/// Строка текста на листе. Заголовок темнее — иначе страница читается
/// как ровная штриховка, а не как документ.
private struct TextLine: View {
    let width: Double
    let height: CGFloat
    let isHeading: Bool

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(SlimlyColor.background.opacity(isHeading ? 0.42 : 0.2))
                .frame(width: proxy.size.width * width, height: height)
        }
        .frame(height: height)
    }
}
