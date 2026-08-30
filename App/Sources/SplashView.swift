import SlimlyDesignSystem
import SwiftUI

/// Заставка при запуске: знак обходит круг, потом открывается приложение.
///
/// Экран запуска из Info.plist — просто заливка цветом фона, поэтому заставка
/// подхватывает уже тёмный кадр, а не проявляется из вспышки.
struct SplashView: View {
    /// Круг закончился и знак сложился — можно уходить на первый экран.
    let onFinish: () -> Void

    @State private var isMarkVisible = false
    @State private var isNameVisible = false
    /// Считает посадки акцента: каждая — короткий удар в ладонь.
    @State private var landings = 0

    var body: some View {
        VStack(spacing: 14) {
            // 117 — сторона сетки знака в макете анимации (холст 150 × 0.78).
            // Крупнее статичного: летящему акценту нужен запас на замах.
            SlimlyLogoMarkAnimation(
                size: 117,
                onLanding: { landings += 1 },
                onFinish: onFinish
            )
            .scaleEffect(isMarkVisible ? 1 : 0.94)
            .opacity(isMarkVisible ? 1 : 0)

            Text("Slimly")
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.title)
                .foregroundStyle(SlimlyColor.text)
                .opacity(isNameVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(glow)
        .ignoresSafeArea()
        // Удары набирают силу к последнему углу: рука понимает, что обход
        // заканчивается, раньше, чем это замечает глаз.
        .sensoryFeedback(trigger: landings) { _, count in
            count > 0 ? .impact(weight: .light, intensity: 0.35 + 0.12 * Double(count)) : nil
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.34)) { isMarkVisible = true }
            // Название догоняет знак, а не выезжает вместе с ним: так пауза
            // перед первым экраном читается как проявление, а не как задержка.
            withAnimation(.easeOut(duration: 0.3).delay(0.14)) { isNameVisible = true }
        }
    }

    /// Свет собран вокруг знака, а не у края экрана, как на рабочих экранах:
    /// здесь он — единственное, на что смотрят.
    private var glow: some View {
        GeometryReader { proxy in
            RadialGradient(
                stops: [
                    .init(color: SlimlyColor.splashGlow, location: 0),
                    .init(color: SlimlyColor.background, location: 0.62),
                ],
                center: UnitPoint(x: 0.5, y: 0.32),
                startRadius: 0,
                endRadius: proxy.size.width * 1.2
            )
        }
        .background(SlimlyColor.background)
    }
}
