import SwiftUI

struct CustomTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    @FocusState private var isFocused: Bool
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                }
            }
            .font(.body)
            .foregroundColor(.offWhiteText)
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.darkGraySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(isFocused ? Color.ivoryAccent : Color.clear, lineWidth: 1.5)
                    )
            )
            .focused($isFocused)
            .accessibilityLabel(placeholder)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.medium) {
        CustomTextField("Email", text: .constant(""))
        CustomTextField("Şifre", text: .constant(""), isSecure: true)
        CustomTextField("Email", text: .constant("test@example.com"))
    }
    .padding()
    .background(Color.charcoalBackground)
}