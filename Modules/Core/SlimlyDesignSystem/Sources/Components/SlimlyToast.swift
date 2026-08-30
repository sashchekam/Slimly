import SwiftUI

/// Подтверждение действия, у которого нет видимых последствий: «скопировано»,
/// «сброшено».
///
/// Не алерт: сообщение ничего не спрашивает и уходит само, поэтому у него нет
/// ни кнопки, ни области нажатия — оно не должно перехватывать палец.
public struct SlimlyToast: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(SlimlyColor.accent)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral100)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Цвет полупрозрачный, поэтому под ним нужен блюр: иначе сообщение
        // читалось бы поверх контента как грязное пятно.
        .background(SlimlyColor.menu, in: shape)
        .background(.ultraThinMaterial, in: shape)
        .shadow(color: .black.opacity(0.55), radius: 15, y: 10)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }
}

public extension View {
    /// Тост поверх экрана. Его жизнь принадлежит состоянию: ViewModel ставит
    /// текст и она же обнуляет — вью не заводит своих таймеров.
    func slimlyToast(_ text: String?) -> some View {
        overlay(alignment: .bottom) {
            if let text {
                SlimlyToast(text)
                    .padding(.horizontal, SlimlySpacing.screenHorizontal)
                    .padding(.bottom, 34)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: text)
    }
}
