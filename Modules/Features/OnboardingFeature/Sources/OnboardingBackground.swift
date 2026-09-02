import SlimlyDesignSystem
import SwiftUI

/// Фон вводного тура: свет собран сверху по центру, а не у левого угла,
/// как на рабочих экранах.
///
/// Здесь нет ни списка, ни шапки — смотрят в иллюстрацию, и пятно стоит
/// прямо над ней. К низу фон уходит темнее основного: кнопка внизу должна
/// лежать на самом глухом участке.
struct OnboardingBackground: View {
    var body: some View {
        SlimlyColor.tourEdge
            .overlay {
                GeometryReader { proxy in
                    EllipticalGradient(
                        stops: [
                            .init(color: SlimlyColor.tourGlow, location: 0),
                            .init(color: SlimlyColor.background, location: 0.58),
                            .init(color: SlimlyColor.tourEdge, location: 1),
                        ],
                        center: .center,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.5
                    )
                    // Эллипс шире экрана и ниже половины его высоты — свет
                    // должен гаснуть примерно там, где начинается текст.
                    .frame(width: proxy.size.width * 2.4, height: proxy.size.height * 1.2)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.04)
                }
            }
    }
}
