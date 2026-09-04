import SlimlyDesignSystem
import SwiftUI

/// Заставка при запуске: знак обходит круг, потом открывается приложение.
///
/// Экран запуска (`LaunchScreen.storyboard`) уже показывает первый кадр —
/// ту же заливку и тот же знак в центре, — поэтому заставка ничего не
/// проявляет: она подхватывает готовый кадр и просто оживляет его.
struct SplashView: View {
    /// Круг закончился и знак сложился — можно уходить на первый экран.
    let onFinish: () -> Void

    /// Считает посадки акцента: каждая — короткий удар в ладонь.
    @State
    private var landings = 0

    var body: some View {
        // 117 — сторона сетки знака в макете анимации (холст 150 × 0.78).
        // Крупнее статичного: летящему акценту нужен запас на замах.
        SlimlyLogoMarkAnimation(
            size: 117,
            onLanding: { landings += 1 },
            onFinish: onFinish
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(glow)
        .ignoresSafeArea()
        // Удары набирают силу к последнему углу: рука понимает, что обход
        // заканчивается, раньше, чем это замечает глаз.
        .sensoryFeedback(trigger: landings) { _, count in
            count > 0 ? .impact(weight: .light, intensity: 0.35 + 0.12 * Double(count)) : nil
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
