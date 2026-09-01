import SwiftUI

/// Подтверждение действия, у которого нет видимых последствий: «скопировано»,
/// «сохранено», «сброшено».
///
/// Не алерт: сообщение ничего не спрашивает и уходит само, поэтому у него нет
/// ни кнопки, ни области нажатия — оно не должно перехватывать палец.
public struct SlimlyToast: View {
    private let text: String
    private let icon: SlimlyIcon.Kind?

    /// - Parameter icon: значок в кружке слева. Без него остаётся акцентная
    ///   точка: она отмечает начало строки, но ничего не обещает, — а галочка
    ///   рядом с «не удалось» сказала бы неправду.
    public init(_ text: String, icon: SlimlyIcon.Kind? = nil) {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 10) {
            marker

            Text(text)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral100)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Слева поля меньше: кружок значка уже несёт свой воздух, и равные
        // отступы сдвинули бы строку вправо от оптического центра.
        .padding(.leading, icon == nil ? 15 : 11)
        .padding(.trailing, 16)
        .padding(.vertical, icon == nil ? 12 : 10)
        // Цвет полупрозрачный, поэтому под ним нужен блюр: иначе сообщение
        // читалось бы поверх контента как грязное пятно.
        .background(SlimlyColor.menu, in: shape)
        .background(.ultraThinMaterial, in: shape)
        .overlay(edge)
        .background(halo)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    /// Скругление «до упора»: на одну строку это капсула, на две — стадион
    /// с крупным радиусом. Прямые углы у сообщения, которое всплывает
    /// и уходит, делают его похожим на карточку контента.
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SlimlyRadius.pill, style: .continuous)
    }

    @ViewBuilder
    private var marker: some View {
        if let icon {
            SlimlyIcon(icon, width: 11)
                .foregroundStyle(SlimlyColor.accent200)
                .frame(width: 22, height: 22)
                .background(SlimlyColor.accentTint(20), in: Circle())
                .overlay(Circle().strokeBorder(SlimlyColor.accentTint(32), lineWidth: 1))
        } else {
            Circle()
                .fill(SlimlyColor.accent)
                .frame(width: 6, height: 6)
        }
    }

    /// Верхняя кромка светлее нижней: так стекло ловит свет сверху, как весь
    /// остальной Nocturne, и не выглядит наклейкой поверх экрана.
    private var edge: some View {
        shape.strokeBorder(
            LinearGradient(
                colors: [
                    SlimlyColor.neutral100.opacity(0.16),
                    SlimlyColor.neutral100.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            lineWidth: 1
        )
    }

    /// Тень только вокруг подложки, а не под ней.
    ///
    /// Обычная тень у полупрозрачного стекла просвечивает насквозь: середина
    /// сообщения темнеет, и оно выглядит замусоленным. Поэтому тень отбрасывает
    /// отдельный слой, у которого сам прямоугольник вырезан маской, — остаётся
    /// один ореол по краю.
    private var halo: some View {
        shape
            .fill(SlimlyColor.background)
            .shadow(color: .black.opacity(0.5), radius: 16, y: 9)
            .mask {
                Rectangle()
                    // Маска обязана быть шире тоста: ореол уходит за его края,
                    // и по границе кадра он бы обрезался видимой линией.
                    .padding(-60)
                    .overlay(shape.blendMode(.destinationOut))
                    .compositingGroup()
            }
    }
}

public extension View {
    /// Тост поверх экрана. Его жизнь принадлежит состоянию: ViewModel ставит
    /// текст и она же обнуляет — вью не заводит своих таймеров.
    func slimlyToast(_ text: String?, icon: SlimlyIcon.Kind? = nil) -> some View {
        overlay(alignment: .bottom) {
            if let text {
                SlimlyToast(text, icon: icon)
                    .padding(.horizontal, SlimlySpacing.screenHorizontal)
                    .padding(.bottom, 34)
                    .transition(.slimlyToast)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: text)
    }
}

public extension AnyTransition {
    /// Появление тоста: подъём снизу с лёгким «раскрытием». Масштаб взят
    /// у нижнего края — сообщение растёт из-под края экрана, а не из воздуха.
    static var slimlyToast: AnyTransition {
        .move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.94, anchor: .bottom))
    }
}
