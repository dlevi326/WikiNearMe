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
    
    enum ViewMode {
        case list, map
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Demo location banner
                if locationManager.isUsingDemoLocation {
                    DemoLocationBanner(locationManager: locationManager)
                }
                
                // Controls
                VStack(spacing: 12) {
                    // Search bar and location button
                    HStack {
                        TextField("Search location...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                Task {
                                    await viewModel.searchLocation(searchText)
                                }
                            }
                        
                        Button {
                            Task {
                                await viewModel.useCurrentLocation(from: locationManager)
                            }
                        } label: {
                            Image(systemName: "location.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Radius slider
                    HStack {
                        Text("Radius:")
                            .font(.subheadline)
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.radiusMiles },
                                set: { viewModel.setRadiusMiles($0) }
                            ),
                            in: 0.1...5.0,
                            step: 0.1
                        )
                        
                        Text(String(format: "%.1f mi", viewModel.radiusMiles))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    // View mode and refresh
                    HStack {
                        Picker("View", selection: $viewMode) {
                            Text("List").tag(ViewMode.list)
                            Text("Map").tag(ViewMode.map)
                        }
                        .pickerStyle(.segmented)
                        
                        Button {
                            Task {
                                await viewModel.refreshArticles()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Content
                ZStack {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Discovering nearby articles...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView {
                            Label("Error", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("Retry") {
                                Task {
                                    await viewModel.refreshArticles()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if viewModel.articles.isEmpty {
                        ContentUnavailableView(
                            "No Articles Found",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Try increasing the search radius or searching a different location")
                        )
                    } else {
                        // Show list or map
                        switch viewMode {
                        case .list:
                            ArticleListView(
                                articles: viewModel.articles,
                                selectedArticle: $viewModel.selectedArticle
                            )
                        case .map:
                            ArticleMapView(
                                articles: viewModel.articles,
                                selectedArticle: $viewModel.selectedArticle
                            )
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
}

/// Banner shown when using demo location
struct DemoLocationBanner: View {
    let locationManager: LocationManager
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
            
            Text("Using demo city (NYC). Enable location in Settings to use your location.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Settings") {
                locationManager.openSettings()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
}

#Preview {
    NearbyView(viewModel: NearbyViewModel())
        .environment(LocationManager())
        .modelContainer(for: Bookmark.self, inMemory: true)
}
