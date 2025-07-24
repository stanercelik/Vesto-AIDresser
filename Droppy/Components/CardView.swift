import SwiftUI

struct CardView<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.darkGraySurface)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Kart Başlığı")
                .font(.headline)
                .foregroundColor(.offWhiteText)
            
            Text("Bu bir kart içeriği örneğidir. Kartlar bilgileri gruplamak için kullanılır.")
                .font(.body)
                .foregroundColor(.lightGraySecondary)
        }
    }
    .padding()
    .background(Color.charcoalBackground)
}