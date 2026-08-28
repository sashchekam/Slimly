import SwiftUI
import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation
import WelcomeFeatureInterface

public struct WelcomeView: View {
    @State private var viewModel: WelcomeViewModel

    public init(viewModel: WelcomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: SlimlySpacing.l) {
            Spacer()

            VStack(spacing: SlimlySpacing.s) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SlimlyColor.accent)

                Text("Slimly")
                    .font(.slimlyTitle)
                    .foregroundStyle(SlimlyColor.textPrimary)

                Text("Лёгкий путь к своей форме")
                    .font(.slimlySubtitle)
                    .foregroundStyle(SlimlyColor.textSecondary)
            }

            VStack(spacing: SlimlySpacing.s) {
                TextField("Почта", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Пароль", text: $viewModel.password)
                    .textContentType(.password)
            }
            .padding(SlimlySpacing.m)
            .background(SlimlyColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.card, style: .continuous))

            if let errorText = viewModel.errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                Task { await viewModel.submit() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Войти")
                }
            }
            .buttonStyle(.slimlyPrimary)
            .disabled(!viewModel.isSubmitEnabled)
        }
        .padding(SlimlySpacing.l)
        .background(SlimlyColor.background)
    }
}

#Preview {
    WelcomeView(
        viewModel: WelcomeViewModel(
            authService: StubAuthService(),
            router: Router(root: WelcomeRoute.signIn)
        )
    )
}
