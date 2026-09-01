import SwiftUI

/// Обвязка нижней шторки: ручка, поверхность и заголовок с «Отменой».
///
/// Высоту экран объявляет сам — модификатором `sheetHeight` из
/// SlimlyNavigation: изнутри слоя `presentationDetents` до шита не доходит,
/// и применить его может только хост. Контент лежит в скролле: при крупном
/// системном шрифте шторка не должна обрезать кнопку действия.
public struct SlimlySheetScaffold<Content: View>: View {
    private let title: String
    /// Подпись кнопки закрытия. У шторки-настройки это «Отмена», но там,
    /// где отменять нечего — просмотр готового файла, — уместно «Готово».
    private let closeTitle: String
    private let onCancel: () -> Void
    private let content: Content

    public init(
        title: String,
        closeTitle: String = "Отмена",
        onCancel: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.closeTitle = closeTitle
        self.onCancel = onCancel
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(SlimlyColor.text.opacity(0.18))
                .frame(width: 38, height: 4)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .tracking(-0.3)
                    // Заголовком бывает имя файла: у него значимы начало
                    // и расширение, а не середина.
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 0)

                Button(closeTitle, action: onCancel)
                    .buttonStyle(SlimlyLinkButtonStyle(font: .system(size: 15)))
            }

            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(SlimlyColor.text)
        // Поверхность рисуем сами: `presentationBackground` изнутри слоя до
        // шита не доходит, как и `presentationDetents`. Фон уходит под
        // домашний индикатор — иначе у нижнего края остаётся полоса окна.
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: SlimlyRadius.sheet,
                topTrailingRadius: SlimlyRadius.sheet,
                style: .continuous
            )
            .fill(SlimlyColor.sheet)
            .ignoresSafeArea(edges: .bottom)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(SlimlyRadius.sheet)
    }
}
