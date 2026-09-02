import SlimlyDesignSystem
import SwiftUI

/// Три файла ужимаются один за другим, под ними проявляется итог.
///
/// Полосы уходят до трети длины: цифра «−58 %» под ними должна читаться
/// как подпись к тому, что уже видно, а не как отдельное утверждение.
struct CompressIllustration: View {
    /// Задержки строк. Полосы стартуют вместе, но ужимаются по очереди —
    /// так видно, что файлов несколько, а не один длинный.
    private static let rows: [(delay: Double, opacity: Double)] = [
        (0, 1),
        (0.18, 0.6),
        (0.36, 0.32),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(spacing: 9) {
                ForEach(Self.rows, id: \.delay) { row in
                    ShrinkRow(delay: row.delay)
                        .opacity(row.opacity)
                }
            }

            SavingLabel()
                // Подпись выровнена не по краю картинки, а по началу полос:
                // она относится к ним, а не ко всему блоку.
                .padding(.leading, 44)
        }
    }
}

/// Миниатюра файла и полоса его размера.
private struct ShrinkRow: View {
    let delay: Double

    var body: some View {
        HStack(spacing: 10) {
            SlimlyStripes.thumbnail
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            KeyframeAnimator(initialValue: 1.0, repeating: true) { fraction in
                GeometryReader { proxy in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [SlimlyColor.accent, SlimlyColor.accent300],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * fraction)
                }
            } keyframes: { _ in
                LinearKeyframe(1, duration: 0.47 + delay)
                CubicKeyframe(0.34, duration: 1.35)
                // Круг у всех строк одной длины: задержка съедается хвостом,
                // иначе полосы за минуту расходятся и стая распадается.
                LinearKeyframe(0.34, duration: 0.78 - delay)
            }
            .frame(height: 9)
            .background(SlimlyColor.text.opacity(0.09), in: Capsule())
        }
    }
}

/// «−58 % · 1,4 ГБ → 590 МБ» — появляется, когда полосы уже ужались.
private struct SavingLabel: View {
    private struct Phase {
        var opacity = 0.0
        var offset: CGFloat = 4
    }

    var body: some View {
        KeyframeAnimator(initialValue: Phase(), repeating: true) { phase in
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("−58%")
                    .font(.system(size: 26, weight: .medium))
                    .tracking(SlimlyTracking.title)
                    .foregroundStyle(SlimlyColor.accent200)

                Text("1,4 ГБ → 590 МБ")
                    .font(.slimlyBodySmall)
                    .foregroundStyle(SlimlyColor.neutral400)
            }
            .opacity(phase.opacity)
            .offset(y: phase.offset)
        } keyframes: { _ in
            KeyframeTrack(\.opacity) {
                LinearKeyframe(0, duration: 0.57)
                CubicKeyframe(1, duration: 0.52)
                LinearKeyframe(1, duration: 1.25)
                LinearKeyframe(0, duration: 0.26)
            }
            KeyframeTrack(\.offset) {
                LinearKeyframe(4, duration: 0.57)
                CubicKeyframe(0, duration: 0.52)
                LinearKeyframe(0, duration: 1.51)
            }
        }
    }
}
