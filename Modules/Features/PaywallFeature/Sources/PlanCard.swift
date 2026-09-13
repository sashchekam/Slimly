import SlimlyDesignSystem
import SwiftUI

/// Строка тарифа: срок, цена и отметка выбора.
///
/// Выбранный отличается кромкой и заполненной точкой, а не заливкой во всю
/// карточку: в Nocturne акцент — это линия, и залитая строка спорила бы
/// с кнопкой внизу за роль главного действия.
struct PlanCard: View {
    let plan: PaywallViewModel.Plan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                mark

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 15, weight: .medium))
                            .tracking(-0.2)

                        if let badge = plan.badge {
                            SlimlyDeltaBadge(badge)
                        }
                    }

                    if let note = plan.note {
                        Text(note)
                            .font(.slimlyCaption)
                            .foregroundStyle(SlimlyColor.neutral500)
                    }
                }

                Spacer(minLength: 8)

                Text(plan.price)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(-0.2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlimlyColor.surface, in: shape)
            .overlay {
                shape.strokeBorder(
                    plan.isSelected ? SlimlyColor.accent : SlimlyColor.text.opacity(0.1),
                    lineWidth: 1
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(plan.isSelected ? [.isSelected] : [])
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
    }

    private var mark: some View {
        Circle()
            .strokeBorder(
                plan.isSelected ? SlimlyColor.accent : SlimlyColor.neutral700,
                lineWidth: 1
            )
            .frame(width: 20, height: 20)
            .overlay {
                if plan.isSelected {
                    Circle()
                        .fill(SlimlyColor.accent)
                        .frame(width: 10, height: 10)
                }
            }
    }
}
