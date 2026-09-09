import SlimlyDesignSystem
import SwiftUI

/// Плашка тарифа — первое, что видно в профиле.
///
/// Два состояния, а не одно с приглушённой кнопкой: подключённая подписка
/// ничего не предлагает и ни о чём не просит, ей достаточно сказать, что она
/// работает. Общего у состояний только знак и марка, поэтому и собраны они
/// порознь, а не одной вёрсткой с ветвлениями внутри.
struct ProCard: View {
    let isActive: Bool
    let note: String
    let status: String
    let pitch: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            // Кромка акцентная у обоих состояний: это по-прежнему один блок,
            // и подключение подписки не должно выглядеть подменой карточки.
            .overlay {
                RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                    .strokeBorder(SlimlyColor.accent700, lineWidth: 1)
            }
    }

    @ViewBuilder
    private var content: some View {
        if isActive {
            active
        } else {
            offer
        }
    }

    // MARK: Подписка подключена

    private var active: some View {
        HStack(spacing: 13) {
            SlimlyProMark(isActive: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(Self.productName)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(-0.2)

                    // Точка вместо слова «статус»: рядом с ней «активен»
                    // читается как показание, а не как заголовок строки.
                    Circle()
                        .fill(SlimlyColor.accent)
                        .frame(width: 5, height: 5)

                    Text(status)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.accent200)
                }

                Text(note)
                    .font(.slimlyCaption)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Подписки нет

    private var offer: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 13) {
                SlimlyProMark(isActive: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.productName)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(-0.2)

                    Text(note)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral500)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(pitch)
                .font(.system(size: 12))
                .foregroundStyle(SlimlyColor.neutral400)
                .fixedSize(horizontal: false, vertical: true)

            // Компактная, а не во всю ширину: подписка — не действие этого
            // экрана, а предложение внутри карточки, и кнопка во всю строку
            // спорила бы с тем, зачем в профиль пришли.
            Button(actionTitle, action: action)
                .buttonStyle(.slimlyCompact)
        }
    }

    /// Имя тарифа не переводится — это марка, а не слово в предложении.
    private static let productName = "Slimly Pro"

    /// Тёплый угол только у подключённой подписки: заливка здесь работает
    /// как «горит», и предложению, от которого ещё можно отказаться,
    /// она обещала бы лишнего.
    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)

        if isActive {
            LinearGradient(
                stops: [
                    .init(color: SlimlyColor.surfaceAccented, location: 0),
                    .init(color: SlimlyColor.surface, location: 0.62),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(shape)
        } else {
            shape.fill(SlimlyColor.surface)
        }
    }
}
