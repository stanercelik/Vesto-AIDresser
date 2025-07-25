//
//  WardrobeView.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import SwiftUI
import Supabase

struct WardrobeView: View {
    @StateObject private var viewModel: WardrobeViewModel
    
    private enum L10n {
        static let title = "Dolabım"
        static let addClothingItem = "Kıyafet Ekle"
        static let emptyWardrobe = "Henüz kıyafet eklemediniz"
        static let emptyWardrobeDescription = "İlk kıyafetinizi eklemek için + butonuna dokunun"
        static let selectFromLibrary = "Fotoğraf Seç"
        static let takePhoto = "Fotoğraf Çek"
        static let cancel = "İptal"
        static let processing = "İşleniyor..."
        static let uploading = "Yükleniyor..."
        static let deleteConfirmation = "Bu kıyafeti silmek istediğinizden emin misiniz?"
        static let delete = "Sil"
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    init(client: SupabaseClient, userId: UUID) {
        self._viewModel = StateObject(
            wrappedValue: WardrobeViewModel(client: client, userId: userId)
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.clothingItems.isEmpty && !viewModel.uploadState.isLoading {
                    emptyStateView
                } else {
                    clothingGridView
                }
                
                if viewModel.uploadState.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(L10n.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSelectionMode {
                        HStack {
                            Button("İptal") {
                                viewModel.toggleSelectionMode()
                            }
                            .foregroundColor(DesignSystem.Colors.accent)
                            
                            if !viewModel.selectedItems.isEmpty {
                                Button {
                                    Task {
                                        await viewModel.deleteSelectedItems()
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSelectionMode {
                        Text("\(viewModel.selectedItems.count) seçili")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        addButton
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadClothingItems()
                }
            }
            .onChange(of: viewModel.selectedImage) { image in
                if image != nil {
                    Task {
                        await viewModel.uploadSelectedImage()
                    }
                }
            }
            .actionSheet(isPresented: $viewModel.showingActionSheet) {
                ActionSheet(
                    title: Text(L10n.addClothingItem),
                    buttons: [
                        .default(Text(L10n.selectFromLibrary)) {
                            viewModel.selectFromLibrary()
                        },
                        .default(Text(L10n.takePhoto)) {
                            viewModel.takePhoto()
                        },
                        .cancel(Text(L10n.cancel))
                    ]
                )
            }
            .sheet(isPresented: $viewModel.showingImagePicker) {
                PhotosPicker(
                    selectedImage: $viewModel.selectedImage,
                    isPresented: $viewModel.showingImagePicker
                )
            }
            .sheet(isPresented: $viewModel.showingCamera) {
                ImagePicker(
                    selectedImage: $viewModel.selectedImage,
                    isPresented: $viewModel.showingCamera,
                    sourceType: .camera
                )
            }
            .alert("Hata", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.dismissError() }
            )) {
                Button("Tamam") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tshirt")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.accent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(L10n.emptyWardrobe)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(L10n.emptyWardrobeDescription)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(
                L10n.addClothingItem,
                isLoading: false
            ) {
                viewModel.showImageSourceOptions()
            }
            .frame(maxWidth: 200)
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var clothingGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.clothingItems) { item in
                    NavigationLink(destination: ClothingDetailView(item: item)) {
                        ClothingItemCard(
                            item: item,
                            isSelectionMode: viewModel.isSelectionMode,
                            isSelected: viewModel.selectedItems.contains(item.id),
                            onSingleDelete: {
                                Task {
                                    await viewModel.deleteClothingItem(item)
                                }
                            },
                            onSelectionToggle: {
                                viewModel.toggleItemSelection(item.id)
                            },
                            onLongPress: {
                                if !viewModel.isSelectionMode {
                                    viewModel.toggleSelectionMode()
                                    viewModel.toggleItemSelection(item.id)
                                }
                            }
                        )
                    }
                    .disabled(viewModel.isSelectionMode)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if viewModel.isSelectionMode {
                                    viewModel.toggleItemSelection(item.id)
                                }
                            }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            viewModel.showImageSourceOptions()
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.accent)
        }
        .disabled(viewModel.uploadState.isLoading)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: viewModel.uploadState.progress)
                    .stroke(
                        DesignSystem.Colors.accent,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.uploadState.progress)
                
                Text("\(viewModel.uploadState.progressPercentage)%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.uploadState.progressPercentage)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text(viewModel.uploadState.statusMessage)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.uploadState.statusMessage)
                    
                    Spacer()
                    
                    Text("\(viewModel.uploadState.progressPercentage)%")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.uploadState.progressPercentage)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.accent)
                            .frame(
                                width: geometry.size.width * viewModel.uploadState.progress,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.5), value: viewModel.uploadState.progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
    
}

struct ClothingItemCard: View {
    let item: ClothingItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSingleDelete: () -> Void
    let onSelectionToggle: () -> Void
    let onLongPress: () -> Void
    
    @State private var showingDeleteAlert = false
    
    private enum L10n {
        static let deleteConfirmation = "Bu kıyafeti silmek istediğinizden emin misiniz?"
        static let delete = "Sil"
        static let cancel = "İptal"
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    AsyncImage(url: URL(string: item.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignSystem.Colors.accent.opacity(0.1))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                            )
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius))
                    .clipped()
                    
                    // Single delete button (top-right corner)
                    if !isSelectionMode {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .background(Color.red.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                    
                    // Selection overlay
                    if isSelectionMode {
                        Rectangle()
                            .fill(Color.black.opacity(isSelected ? 0.3 : 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius))
                        
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : .white)
                                    .background(Color.white.opacity(isSelected ? 0 : 0.3))
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Category section
                HStack {
                    Text(item.category?.localizedName ?? "Kategori yok")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.cardBackground)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .onLongPressGesture {
            onLongPress()
        }
        .alert(L10n.deleteConfirmation, isPresented: $showingDeleteAlert) {
            Button(L10n.cancel, role: .cancel) { }
            Button(L10n.delete, role: .destructive) {
                onSingleDelete()
            }
        }
    }
}
