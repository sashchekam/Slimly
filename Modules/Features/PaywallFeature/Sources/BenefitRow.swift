import SlimlyDesignSystem
import SwiftUI

/// Строка списка «что даёт тариф»: галочка и одна фраза.
///
/// Без заголовков и подписей: каждая строка — законченное обещание, а список
/// целиком читается на одном дыхании перед ценой.
struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SlimlyIcon(.check, width: 11)
                .foregroundStyle(SlimlyColor.accent200)
                .frame(width: 20, height: 20)
                .background(SlimlyColor.accentTint(12), in: Circle())

            Text(text)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.neutral200)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Галочка стоит на строке текста, а не над ней: у иконки
                // свой кружок, и без сдвига он висит выше первой строки.
                .padding(.top, 1)
        }
    }
}
