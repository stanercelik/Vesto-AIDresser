//
//  ClothingDetailView.swift
//  Droppy
//
//  Created by Taner Çelik on 25.07.2025.
//

import SwiftUI

struct ClothingDetailView: View {
    let item: ClothingItem
    @Environment(\.presentationMode) var presentationMode
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var showingFullDescription = false
    @State private var detailsOpacity: Double = 0.0
    @State private var detailsOffset: CGFloat = 50
    @State private var scrollOffset: CGFloat = 0
    
    private enum L10n {
        static let back = "Geri"
        static let category = "Kategori"
        static let color = "Ana Renk"
        static let secondaryColors = "Yan Renkler"
        static let style = "Stil"
        static let occasions = "Ortamlar"
        static let weather = "Hava Durumu"
        static let fabric = "Kumaş"
        static let texture = "Doku"
        static let description = "Açıklama"
        static let showMore = "Daha Fazla"
        static let showLess = "Daha Az"
        static let noDescription = "Açıklama mevcut değil"
        static let unknown = "Belirtilmemiş"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollViewWithOffset(onOffsetChange: { offset in
                    scrollOffset = offset
                }) {
                    VStack(spacing: 0) {
                        // Sticky header image section
                        stickyHeaderImageSection(geometry: geometry)
                        
                        // Details section
                        detailsSection
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Back button overlay
                backButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🔍 ClothingDetailView appeared for item: \(item.id)")
            print("🔍 Item category: \(item.category?.localizedName ?? "nil")")
            
            // Haptic feedback when view appears
            HapticFeedback.impact(.light)
            
            // Animate details section entrance
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                detailsOpacity = 1.0
                detailsOffset = 0
            }
        }
    }
    
    // MARK: - Sticky Header Image Section
    @ViewBuilder
    private func stickyHeaderImageSection(geometry: GeometryProxy) -> some View {
        let maxHeight: CGFloat = geometry.size.height * 0.6
        let minHeight: CGFloat = max(geometry.safeAreaInsets.top + 80, 140)
        let offset = max(scrollOffset, 0)
        
        // Calculate dynamic height with smoother transition
        let currentHeight = max(minHeight, maxHeight - offset * 0.8)
        
        // Calculate scale for zoom effect with better progression
        let progressRatio = min(offset / (maxHeight - minHeight), 1.0)
        let dynamicScale = 1.0 + (progressRatio * 0.2) // Scale from 1.0 to 1.2
        
        ZStack {
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(imageScale * dynamicScale)
                    .offset(imageOffset)
                    .animation(.easeOut(duration: 0.1), value: dynamicScale)
            } placeholder: {
                Rectangle()
                    .fill(DesignSystem.Colors.accent.opacity(0.1))
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                                .scaleEffect(1.2)
                            
                            Text("Yükleniyor...")
                                .font(DesignSystem.Fonts.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    )
            }
            .frame(width: geometry.size.width, height: currentHeight)
            .clipped()
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        imageScale = value.magnitude
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            imageScale = 1.0
                        }
                    }
                    .simultaneously(with:
                        DragGesture()
                            .onChanged { value in
                                imageOffset = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    imageOffset = .zero
                                }
                            }
                    )
            )
            
            // Gradient overlay at bottom for better text readability
            LinearGradient(
                colors: [
                    Color.clear,
                    DesignSystem.Colors.background.opacity(0.3),
                    DesignSystem.Colors.background.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: currentHeight)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Back Button
    @ViewBuilder
    private var backButton: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                
                Text(L10n.back)
                    .font(DesignSystem.Fonts.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                    .fill(DesignSystem.Colors.background.opacity(0.8))
                    .background(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius))
        }
        .padding(.top, 50)
        .padding(.leading, 16)
    }
    
    // MARK: - Details Section
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            VStack(alignment: .leading, spacing: Spacing.large) {
                // Header with category and style
                headerSection
                
                // Colors section
                if item.color != nil || item.secondaryColors?.isEmpty == false {
                    colorsSection
                }
                
                // Attributes grid
                attributesGrid
                
                // Description section
                if let description = item.description, !description.isEmpty {
                    descriptionSection(description: description)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.xl)
            .padding(.bottom, 100) // Extra padding at bottom for scroll
        }
        .opacity(detailsOpacity)
        .offset(y: detailsOffset)
        .background(
            RoundedRectangle(cornerRadius: Spacing.large)
                .fill(DesignSystem.Colors.background)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let category = item.category {
                Text(category.localizedName)
                    .font(DesignSystem.Fonts.title1)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            if let style = item.style {
                Text(style.localizedName)
                    .font(DesignSystem.Fonts.headline)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
        }
    }
    
    // MARK: - Colors Section
    @ViewBuilder
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let mainColor = item.color {
                DetailRow(
                    title: L10n.color,
                    content: {
                        HStack(spacing: Spacing.small) {
                            ColorIndicator(colorName: mainColor)
                            Text(mainColor)
                                .font(DesignSystem.Fonts.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                )
            }
            
            if let secondaryColors = item.secondaryColors, !secondaryColors.isEmpty {
                DetailRow(
                    title: L10n.secondaryColors,
                    content: {
                        HStack(spacing: Spacing.small) {
                            ForEach(secondaryColors, id: \.self) { color in
                                HStack(spacing: 4) {
                                    ColorIndicator(colorName: color)
                                    Text(color)
                                        .font(DesignSystem.Fonts.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Attributes Grid
    @ViewBuilder
    private var attributesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), alignment: .leading),
            GridItem(.flexible(), alignment: .leading)
        ], spacing: Spacing.medium) {
            
            if let occasions = item.occasionTypes, !occasions.isEmpty {
                AttributeCard(
                    icon: "calendar",
                    title: L10n.occasions,
                    values: occasions.map { $0.localizedName }
                )
            }
            
            if let weather = item.weatherSuitability, !weather.isEmpty {
                AttributeCard(
                    icon: "thermometer",
                    title: L10n.weather,
                    values: weather.map { $0.localizedName }
                )
            }
            
            if let fabric = item.fabricType {
                AttributeCard(
                    icon: "scissors",
                    title: L10n.fabric,
                    values: [fabric]
                )
            }
            
            if let texture = item.texture {
                AttributeCard(
                    icon: "hand.raised",
                    title: L10n.texture,
                    values: [texture]
                )
            }
        }
    }
    
    // MARK: - Description Section
    @ViewBuilder
    private func descriptionSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.description)
                .font(DesignSystem.Fonts.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(showingFullDescription ? description : String(description.prefix(120)) + (description.count > 120 ? "..." : ""))
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(showingFullDescription ? nil : 3)
                    .animation(.easeInOut(duration: 0.3), value: showingFullDescription)
                
                if description.count > 120 {
                    Button(action: {
                        HapticFeedback.impact(.light)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFullDescription.toggle()
                        }
                    }) {
                        Text(showingFullDescription ? L10n.showLess : L10n.showMore)
                            .font(DesignSystem.Fonts.body)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
    }
}

// MARK: - Supporting Views

struct DetailRow<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(DesignSystem.Fonts.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
            
            content()
        }
    }
}

struct ColorIndicator: View {
    let colorName: String
    
    private var color: Color {
        switch colorName.lowercased() {
        case "mavi", "blue": return .blue
        case "kırmızı", "red": return .red
        case "beyaz", "white": return .white
        case "siyah", "black": return .black
        case "yeşil", "green": return .green
        case "sarı", "yellow": return .yellow
        case "turuncu", "orange": return .orange
        case "mor", "purple": return .purple
        case "pembe", "pink": return .pink
        case "kahverengi", "brown": return .brown
        case "gri", "gray", "grey": return .gray
        case "lacivert", "navy": return Color.blue.opacity(0.7)
        default: return DesignSystem.Colors.accent
        }
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AttributeCard: View {
    let icon: String
    let title: String
    let values: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text(title)
                    .font(DesignSystem.Fonts.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .textCase(.uppercase)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(DesignSystem.Fonts.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.smallCornerRadius)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
}


// MARK: - Custom ScrollView with Offset Tracking
struct ScrollViewWithOffset<Content: View>: View {
    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content
    
    init(onOffsetChange: @escaping (CGFloat) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onOffsetChange = onOffsetChange
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
            }
            .frame(height: 0)
            
            content()
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            onOffsetChange(-value)
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct ClothingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ClothingDetailView(
            item: ClothingItem(
                userId: UUID(),
                imageUrl: "https://example.com/tshirt.jpg",
                description: "Mavi pamuklu V yaka t-shirt. Günlük kullanım için idealdir. Yumuşak dokusu ve rahat kesimi ile tüm gün konforlu hissetmenizi sağlar.",
                category: .tshirt,
                color: "Mavi",
                secondaryColors: ["Beyaz", "Lacivert"],
                style: .casual,
                occasionTypes: [.casual, .shopping],
                weatherSuitability: [.warm, .hot],
                fabricType: "Pamuk",
                texture: "Düz"
            )
        )
        .preferredColorScheme(.dark)
    }
}