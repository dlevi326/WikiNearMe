//
//  NearbyView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI

/// Main view for discovering nearby Wikipedia articles
struct NearbyView: View {
    @Environment(LocationManager.self) private var locationManager
    @Bindable var viewModel: NearbyViewModel
    
    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""
    @State private var showingDetail = false
    @State private var isSearchFocused = false
    
    enum ViewMode {
        case list, map
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Demo location banner
                    if locationManager.isUsingDemoLocation {
                        DemoLocationBanner(locationManager: locationManager)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    controlsCard
                
                    contentView
                }
                .overlay(alignment: .top) {
                    // Suggestions dropdown overlay at VStack level
                    if !viewModel.locationSuggestions.isEmpty {
                        GeometryReader { geometry in
                            suggestionsDropdown
                                .frame(maxWidth: geometry.size.width - 72)
                                .padding(.horizontal, 36)
                                .padding(.top, locationManager.isUsingDemoLocation ? 144 : 84)
                        }
                    }
                }
            }
            .navigationTitle("NearbyWiki")
            .sheet(isPresented: Binding(
                get: { viewModel.selectedArticle != nil && viewMode == .list },
                set: { if !$0 { viewModel.clearSelection() } }
            )) {
                if let article = viewModel.selectedArticle {
                    NavigationStack {
                        ArticleDetailView(article: article)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        viewModel.clearSelection()
                                    }
                                }
                            }
                    }
                }
            }
            .task {
                // Initial load
                if viewModel.currentCoordinate == nil {
                    if let location = await locationManager.fetchLocation() {
                        viewModel.currentCoordinate = location
                        await viewModel.refreshArticles()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var controlsCard: some View {
        VStack(spacing: 16) {
            searchBar
            radiusSlider
            viewModeControls
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                TextField("Search location...", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        viewModel.fetchLocationSuggestions(for: newValue)
                    }
                    .onSubmit {
                        Task {
                            await viewModel.searchLocation(searchText)
                            isSearchFocused = false
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.locationSuggestions = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
            
            Button {
                Task {
                    await viewModel.useCurrentLocation(from: locationManager)
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .blue.opacity(0.3), radius: 5, y: 2)
            }
        }
    }
    
    private var suggestionsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.locationSuggestions) { suggestion in
                Button {
                    searchText = suggestion.title
                    Task {
                        await viewModel.selectLocationSuggestion(suggestion)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if suggestion.id != viewModel.locationSuggestions.last?.id {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
    }
    
    private var radiusSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Search Radius")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.1f mi", viewModel.radiusMiles))
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.radiusMiles },
                    set: { viewModel.setRadiusMiles($0) }
                ),
                in: 0.1...5.0,
                step: 0.1
            )
            .tint(.blue)
        }
    }
    
    private var viewModeControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Picker("View", selection: $viewMode) {
                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                    Label("Map", systemImage: "map").tag(ViewMode.map)
                }
                .pickerStyle(.segmented)
                
                Button {
                    Task {
                        await viewModel.refreshArticles()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(viewModel.isLoading ? Color.secondary : Color.blue)
                }
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                )
                .disabled(viewModel.isLoading)
                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                .animation(
                    viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                    value: viewModel.isLoading
                )
            }
            
            // Sort picker
            Picker("Sort by", selection: $viewModel.sortOption) {
                ForEach(NearbyViewModel.SortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var contentView: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error: error)
            } else if viewModel.articles.isEmpty {
                emptyView
            } else {
                articlesView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.articles.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: viewMode)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            Text("Discovering nearby articles...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
    
    private func errorView(error: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        } description: {
            Text(error)
                .multilineTextAlignment(.center)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.refreshArticles()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .transition(.opacity)
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Articles Found",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Try increasing the search radius or searching a different location")
        )
        .transition(.opacity)
    }
    
    private var articlesView: some View {
        Group {
            switch viewMode {
            case .list:
                ArticleListView(
                    articles: viewModel.articles,
                    selectedArticle: $viewModel.selectedArticle
                )
                .transition(.opacity)
            case .map:
                ArticleMapView(
                    articles: viewModel.articles,
                    selectedArticle: $viewModel.selectedArticle
                )
                .transition(.opacity)
            }
        }
    }
}

/// Banner shown when using demo location
struct DemoLocationBanner: View {
    let locationManager: LocationManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
            
            Text("Using demo city (NYC). Enable location in Settings to use your location.")
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button("Settings") {
                locationManager.openSettings()
            }
            .font(.caption)
            .fontWeight(.medium)
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.orange.opacity(0.2)),
            alignment: .bottom
        )
    }
}

#Preview {
    NearbyView(viewModel: NearbyViewModel())
        .environment(LocationManager())
        .modelContainer(for: Bookmark.self, inMemory: true)
}
