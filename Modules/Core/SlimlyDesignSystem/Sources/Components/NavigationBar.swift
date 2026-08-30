import SwiftUI

/// Шапка экрана: шеврон «назад» слева, круглая кнопка справа.
///
/// Системная панель везде скрыта (`slimlyScreen()`), потому что макет
/// рисует и заголовок, и возврат сам: заголовок живёт в контенте и уезжает
/// со скроллом, а в шапке остаётся только навигация. Названия предыдущего
/// экрана рядом с шевроном нет — оно дублирует заголовок, к которому ведёт.
public struct SlimlyNavigationBar<Trailing: View>: View {
    private let onBack: (() -> Void)?
    private let trailing: Trailing

    public init(
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    SlimlyIcon(.chevronLeft, width: 8)
                        .foregroundStyle(SlimlyColor.accent300)
                        // Сам шеврон крошечный: без явной области нажатия
                        // в него трудно попасть пальцем.
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Назад")
            }

            Spacer(minLength: 0)

            trailing
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

public extension SlimlyNavigationBar where Trailing == EmptyView {
    init(onBack: (() -> Void)? = nil) {
        self.init(onBack: onBack) { EmptyView() }
    }
}

/// Круглая кнопка-иконка в шапке — вход в профиль.
public struct SlimlyCircleButton: View {
    private let icon: SlimlyIcon.Kind
    private let accessibilityLabel: String
    private let action: () -> Void

    public init(
        icon: SlimlyIcon.Kind,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            SlimlyIcon(icon, width: 24)
                .foregroundStyle(SlimlyColor.neutral300)
                .frame(width: 44, height: 44)
                .background(SlimlyColor.surface, in: Circle())
                .overlay(Circle().strokeBorder(SlimlyColor.text.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
