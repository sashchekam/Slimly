import SlimlyDesignSystem
import SwiftUI

/// Дорожка колеблется, под ней проявляется, во что она превратится.
struct AudioIllustration: View {
    /// Сдвиг фазы каждого столбика. Ряд неровный намеренно: ровная волна
    /// читается как индикатор загрузки, а не как звук.
    private static let offsets: [Double] = [
        0.22, 0.55, 0.9, 0.4, 0.72, 0.15, 0.62, 0.95, 0.3,
        0.5, 0.85, 0.2, 0.68, 0.42, 0.78, 0.28, 0.58, 0.35,
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(Self.offsets.enumerated()), id: \.offset) { index, phase in
                    WaveBar(delay: phase * 1.1)
                        .id(index)
                }
            }
            .frame(height: 78, alignment: .bottom)

            ResultPill()
        }
    }
}

/// Столбик дорожки: качается между четвертью и полной высотой.
private struct WaveBar: View {
    let delay: Double

    @State
    private var isRaised = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [SlimlyColor.accent200, SlimlyColor.accent600],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 5, height: 70)
            .scaleEffect(y: isRaised ? 1 : 0.22, anchor: .bottom)
            .animation(
                .easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(delay),
                value: isRaised
            )
            .onAppear { isRaised = true }
    }
}

/// «MOV → M4A · 4,2 МБ»: во что превратится дорожка.
private struct ResultPill: View {
    var body: some View {
        KeyframeAnimator(initialValue: 0.0, repeating: true) { opacity in
            HStack(spacing: 9) {
                Text(verbatim: "MOV")
                    .foregroundStyle(SlimlyColor.neutral500)

                Rectangle()
                    .fill(SlimlyColor.neutral600)
                    .frame(width: 14, height: 1)

                Text(L10n.Audio.sample)
                    .foregroundStyle(SlimlyColor.accent200)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(SlimlyColor.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(SlimlyColor.text.opacity(0.12), lineWidth: 1) }
            .opacity(opacity)
        } keyframes: { _ in
            LinearKeyframe(0, duration: 1.43)
            CubicKeyframe(1, duration: 0.52)
            LinearKeyframe(1, duration: 0.44)
            CubicKeyframe(0, duration: 0.21)
        }
    }
}
