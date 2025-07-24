import SwiftUI

struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void
    private let isEnabled: Bool
    private let isLoading: Bool
    
    init(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && isEnabled {
                HapticFeedback.impact(.heavy)
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .charcoalBackground))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.charcoalBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isEnabled && !isLoading ? Color.ivoryAccent : Color.lightGraySecondary)
            )
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Yükleniyor" : "")
    }
}

#Preview {
    VStack(spacing: Spacing.medium) {
        PrimaryButton("Giriş Yap") {
            print("Primary button tapped")
        }
        
        PrimaryButton("Giriş Yap", isEnabled: false) {
            print("Disabled button tapped")
        }
        
        PrimaryButton("Yükleniyor...", isLoading: true) {
            print("Loading button tapped")
        }
    }
    .padding()
    .background(Color.charcoalBackground)
}