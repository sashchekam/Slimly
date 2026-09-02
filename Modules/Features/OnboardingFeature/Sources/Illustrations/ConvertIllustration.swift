import SlimlyDesignSystem
import SwiftUI

/// Карточка меняет формат и превращается в готовый кадр, под ней — ряд форматов.
struct ConvertIllustration: View {
    private struct Phase {
        var source = 1.0
        var target = 0.0
        var arrow = 0.35
        var arrowScale = 0.94
    }

    /// Ряд под картинкой — те же чипы, что на шаге выбора формата: тур
    /// показывает интерфейс, а не рисует свой.
    private static let formats = ["HEIC", "JPEG", "PNG", "H.264"]
    private static let selected = "JPEG"

    var body: some View {
        VStack(spacing: 18) {
            KeyframeAnimator(initialValue: Phase(), repeating: true) { phase in
                HStack(spacing: 14) {
                    ZStack {
                        FormatCard(format: "HEIC", isTarget: false)
                            .opacity(phase.source)
                        FormatCard(format: "JPEG", isTarget: true)
                            .opacity(phase.target)
                    }

                    SlimlyIcon(.arrowRight, width: 26)
                        .foregroundStyle(SlimlyColor.accent300)
                        .opacity(phase.arrow)
                        .scaleEffect(phase.arrowScale)

                    PaperSurface()
                        .frame(width: 74, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .slimlyElevation(.md, cornerRadius: 9)
                }
            } keyframes: { _ in
                // Круг закрывается обратным перекрёстком: без него подписи
                // на карточке щёлкали бы местами в момент повтора.
                KeyframeTrack(\.source) {
                    LinearKeyframe(1, duration: 0.84)
                    CubicKeyframe(0, duration: 0.7)
                    LinearKeyframe(0, duration: 0.98)
                    CubicKeyframe(1, duration: 0.28)
                }
                KeyframeTrack(\.target) {
                    LinearKeyframe(0, duration: 1.26)
                    CubicKeyframe(1, duration: 0.7)
                    LinearKeyframe(1, duration: 0.56)
                    CubicKeyframe(0, duration: 0.28)
                }
                KeyframeTrack(\.arrow) {
                    CubicKeyframe(1, duration: 1.4)
                    CubicKeyframe(0.35, duration: 1.4)
                }
                KeyframeTrack(\.arrowScale) {
                    CubicKeyframe(1, duration: 1.4)
                    CubicKeyframe(0.94, duration: 1.4)
                }
            }

            HStack(spacing: 7) {
                ForEach(Self.formats, id: \.self) { format in
                    SlimlyChip(format, isSelected: format == Self.selected, style: .onSurface)
                }
            }
        }
    }
}

/// Карточка исходника: контур с названием формата вместо превью.
private struct FormatCard: View {
    let format: String
    /// Формат, в который переводим, подсвечен акцентом — исходник нейтрален.
    let isTarget: Bool

    var body: some View {
        Text(format)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(isTarget ? SlimlyColor.accent100 : SlimlyColor.neutral300)
            .frame(width: 74, height: 92)
            .background(isTarget ? SlimlyColor.accentTint(14) : .clear, in: shape)
            .overlay {
                shape.strokeBorder(
                    isTarget ? SlimlyColor.accent : SlimlyColor.text.opacity(0.14),
                    lineWidth: 1
                )
            }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
    }
}
