import SwiftUI

/// Обвязка нижней шторки: ручка, поверхность и заголовок с «Отменой».
///
/// Высота фиксирована макетом, но контент лежит в скролле: при крупном
/// системном шрифте шторка не должна обрезать кнопку действия.
public struct SlimlySheetScaffold<Content: View>: View {
    private let title: String
    private let height: CGFloat
    /// Подпись кнопки закрытия. У шторки-настройки это «Отмена», но там,
    /// где отменять нечего — просмотр готового файла, — уместно «Готово».
    private let closeTitle: String
    private let onCancel: () -> Void
    private let content: Content

    public init(
        title: String,
        height: CGFloat,
        closeTitle: String = "Отмена",
        onCancel: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.height = height
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
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(SlimlyColor.sheet)
        .presentationCornerRadius(22)
    }
}
