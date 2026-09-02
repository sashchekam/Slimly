import SlimlyDesignSystem
import SwiftUI

/// Метка «DEBUG» поверх приложения: горит, пока включена хоть одна подмена,
/// и по нажатию открывает меню.
///
/// Висит над всей навигацией, а не в шапке экрана: подмена действует везде,
/// и напоминание о ней не должно зависеть от того, куда ушёл пользователь.
public struct DebugStatusChip: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(SlimlyColor.accent)
                    .frame(width: 6, height: 6)

                Text("DEBUG")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .tracking(0.95)
                    .foregroundStyle(SlimlyColor.accent200)
            }
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(SlimlyColor.accent900, in: Capsule())
            .overlay(Capsule().strokeBorder(SlimlyColor.accent600, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Открыть отладочное меню")
    }
}
